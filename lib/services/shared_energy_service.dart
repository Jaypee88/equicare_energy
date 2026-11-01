import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/site_models.dart';

class SharedEnergyService {
  static const _boxName='shared_energy';
  static Future<Box> _box() async => Hive.isBoxOpen(_boxName) ? Hive.box(_boxName) : Hive.openBox(_boxName);

  Future<void> saveSite(EnergySite site) async => (await _box()).put('site:${site.id}',site.toMap());
  Future<List<EnergySite>> sites() async {
    final b=await _box();
    return b.keys.where((k)=>k.toString().startsWith('site:')).map((k)=>EnergySite.fromMap(Map.from(b.get(k) as Map))).toList();
  }
  Future<void> saveRoom(EnergyRoom room) async => (await _box()).put('room:${room.id}',room.toMap());
  Future<List<EnergyRoom>> rooms(String siteId) async {
    final b=await _box();
    return b.keys.where((k)=>k.toString().startsWith('room:')).map((k)=>EnergyRoom.fromMap(Map.from(b.get(k) as Map))).where((r)=>r.siteId==siteId).toList();
  }
  List<RoomAllocation> allocate(EnergySite site,List<EnergyRoom> input) {
    final rooms=input.where((r)=>r.active).toList();
    if(rooms.isEmpty||site.dailyBudgetKwh<0) return [];
    switch(site.allocationPolicy) {
      case AllocationPolicy.equal:
        return rooms.map((r)=>RoomAllocation(r.id,site.dailyBudgetKwh/rooms.length)).toList();
      case AllocationPolicy.weighted:
        final total=rooms.fold<double>(0,(s,r)=>s+r.allocationWeight);
        if(total<=0) throw ArgumentError('At least one positive allocation weight is required.');
        return rooms.map((r)=>RoomAllocation(r.id,site.dailyBudgetKwh*r.allocationWeight/total)).toList();
      case AllocationPolicy.priority:
        final ordered=[...rooms]..sort((a,b)=>b.priority.compareTo(a.priority));
        final result=<RoomAllocation>[];
        var remaining=site.dailyBudgetKwh;
        for(var i=0;i<ordered.length;i++){
          final share=remaining/(ordered.length-i);
          result.add(RoomAllocation(ordered[i].id,share)); remaining-=share;
        }
        return result;
      case AllocationPolicy.manual:
        throw StateError('Manual allocations must be explicitly entered and approved.');
    }
  }
  Future<void> saveConsumption(RoomConsumption c) async {
    if(c.energyKwh<0) throw ArgumentError('Energy cannot be negative.');
    if(c.kind==MeterReadingKind.measured && c.meterId.trim().isEmpty) throw ArgumentError('Measured consumption requires a meter ID.');
    await (await _box()).put('consumption:${c.id}',c.toMap());
  }
  Future<List<RoomConsumption>> consumption(String roomId) async {
    final b=await _box();
    return b.keys.where((k)=>k.toString().startsWith('consumption:')).map((k)=>RoomConsumption.fromMap(Map.from(b.get(k) as Map))).where((r)=>r.roomId==roomId).toList();
  }
  Future<void> audit(AllocationAudit a) async => (await _box()).put('audit:${a.id}',a.toMap());
  Future<List<AllocationAudit>> auditLog(String siteId) async {
    final b=await _box();
    return b.keys.where((k)=>k.toString().startsWith('audit:')).map((k)=>Map<String,dynamic>.from(b.get(k) as Map)).where((m)=>m['siteId']==siteId).map((m)=>AllocationAudit(id:m['id'],siteId:m['siteId'],actor:m['actor'],action:m['action'],details:m['details'],at:DateTime.parse(m['at']))).toList();
  }
}
