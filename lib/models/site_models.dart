enum AllocationPolicy { equal, weighted, priority, manual }
enum MeterReadingKind { measured, simulated, estimated }

class EnergySite {
  final String id, name, type, timezone;
  final double dailyBudgetKwh;
  final AllocationPolicy allocationPolicy;
  const EnergySite({required this.id,required this.name,required this.type,required this.timezone,required this.dailyBudgetKwh,this.allocationPolicy=AllocationPolicy.equal});
  Map<String,dynamic> toMap()=>{'id':id,'name':name,'type':type,'timezone':timezone,'dailyBudgetKwh':dailyBudgetKwh,'allocationPolicy':allocationPolicy.name};
  factory EnergySite.fromMap(Map m)=>EnergySite(id:m['id'],name:m['name'],type:m['type'],timezone:m['timezone']??'UTC',dailyBudgetKwh:(m['dailyBudgetKwh'] as num).toDouble(),allocationPolicy:AllocationPolicy.values.firstWhere((e)=>e.name==m['allocationPolicy'],orElse:()=>AllocationPolicy.equal));
}
class EnergyRoom {
  final String id,siteId,name;
  final double allocationWeight;
  final int priority;
  final bool active;
  const EnergyRoom({required this.id,required this.siteId,required this.name,this.allocationWeight=1,this.priority=0,this.active=true});
  Map<String,dynamic> toMap()=>{'id':id,'siteId':siteId,'name':name,'allocationWeight':allocationWeight,'priority':priority,'active':active};
  factory EnergyRoom.fromMap(Map m)=>EnergyRoom(id:m['id'],siteId:m['siteId'],name:m['name'],allocationWeight:(m['allocationWeight'] as num).toDouble(),priority:m['priority'] as int? ?? 0,active:m['active'] as bool? ?? true);
}
class RoomAllocation {
  final String roomId;
  final double allocatedKwh;
  const RoomAllocation(this.roomId,this.allocatedKwh);
}
class RoomConsumption {
  final String id,roomId,meterId,source;
  final DateTime at;
  final double energyKwh;
  final MeterReadingKind kind;
  const RoomConsumption({required this.id,required this.roomId,required this.meterId,required this.source,required this.at,required this.energyKwh,required this.kind});
  Map<String,dynamic> toMap()=>{'id':id,'roomId':roomId,'meterId':meterId,'source':source,'at':at.toIso8601String(),'energyKwh':energyKwh,'kind':kind.name};
  factory RoomConsumption.fromMap(Map m)=>RoomConsumption(id:m['id'],roomId:m['roomId'],meterId:m['meterId'],source:m['source'],at:DateTime.parse(m['at']),energyKwh:(m['energyKwh'] as num).toDouble(),kind:MeterReadingKind.values.firstWhere((e)=>e.name==m['kind'],orElse:()=>MeterReadingKind.estimated));
}
class AllocationAudit {
  final String id,siteId,actor,action,details;
  final DateTime at;
  const AllocationAudit({required this.id,required this.siteId,required this.actor,required this.action,required this.details,required this.at});
  Map<String,dynamic> toMap()=>{'id':id,'siteId':siteId,'actor':actor,'action':action,'details':details,'at':at.toIso8601String()};
}
