import 'package:flutter_test/flutter_test.dart';
import 'package:equicare_energy/models/site_models.dart';
import 'package:equicare_energy/services/shared_energy_service.dart';

void main() {
  final service = SharedEnergyService();
  final site = EnergySite(id:'s',name:'Demo',type:'hostel',timezone:'UTC',dailyBudgetKwh:12);

  test('equal allocation divides budget evenly', () {
    final rooms = [for(var i=0;i<3;i++) EnergyRoom(id:'r$i',siteId:'s',name:'Room $i')];
    final result = service.allocate(site,rooms);
    expect(result.map((a)=>a.allocatedKwh).toList(), everyElement(closeTo(4,0.0001)));
  });

  test('weighted allocation respects weights and total budget', () {
    final rooms = [
      EnergyRoom(id:'a',siteId:'s',name:'A',allocationWeight:1),
      EnergyRoom(id:'b',siteId:'s',name:'B',allocationWeight:2),
    ];
    final result = service.allocate(EnergySite(id:'s',name:'Demo',type:'hostel',timezone:'UTC',dailyBudgetKwh:12,allocationPolicy:AllocationPolicy.weighted),rooms);
    expect(result[0].allocatedKwh,closeTo(4,0.0001));
    expect(result[1].allocatedKwh,closeTo(8,0.0001));
  });

  test('inactive rooms do not receive allocations', () {
    final rooms = [
      EnergyRoom(id:'a',siteId:'s',name:'A'),
      EnergyRoom(id:'b',siteId:'s',name:'B',active:false),
    ];
    final result = service.allocate(site,rooms);
    expect(result,hasLength(1));
    expect(result.single.roomId,'a');
  });

  test('priority allocation weights rooms proportionally', () {
    final rooms=[EnergyRoom(id:'a',siteId:'s',name:'A',priority:1),EnergyRoom(id:'b',siteId:'s',name:'B',priority:3)];
    final priority=EnergySite(id:'s',name:'Demo',type:'hostel',timezone:'UTC',dailyBudgetKwh:12,allocationPolicy:AllocationPolicy.priority);
    final result=service.allocate(priority,rooms);
    expect(result[0].allocatedKwh,closeTo(3,0.0001));
    expect(result[1].allocatedKwh,closeTo(9,0.0001));
  });

  test('manual allocation is not silently guessed', () {
    final rooms=[EnergyRoom(id:'a',siteId:'s',name:'A')];
    final manual=EnergySite(id:'s',name:'Demo',type:'hostel',timezone:'UTC',dailyBudgetKwh:12,allocationPolicy:AllocationPolicy.manual);
    expect(()=>service.allocate(manual,rooms),throwsStateError);
  });
}
