import 'package:flutter/material.dart';
import '../models/site_models.dart';
import '../services/shared_energy_service.dart';

class SharedEnergyScreen extends StatefulWidget {
 const SharedEnergyScreen({super.key});
 @override State<SharedEnergyScreen> createState()=>_SharedEnergyScreenState();
}
class _SharedEnergyScreenState extends State<SharedEnergyScreen> {
 final _service=SharedEnergyService();
 final _siteName=TextEditingController(text:'Community residence');
 final _budget=TextEditingController(text:'12');
 final _roomName=TextEditingController();
 List<EnergySite> _sites=[];
 List<EnergyRoom> _rooms=[];
 EnergySite? _selected;
 AllocationPolicy _policy=AllocationPolicy.equal;
 String? _message;
 @override void initState(){super.initState();_load();}
 @override void dispose(){_siteName.dispose();_budget.dispose();_roomName.dispose();super.dispose();}
 Future<void> _load() async {final s=await _service.sites();if(!mounted)return;setState(()=>_sites=s);if(s.isNotEmpty)await _select(s.first);}
 Future<void> _select(EnergySite site) async {final rooms=await _service.rooms(site.id);if(!mounted)return;setState(() { _selected=site; _rooms=rooms; _policy=site.allocationPolicy; });}
 String _id()=>DateTime.now().microsecondsSinceEpoch.toString();
 Future<void> _createSite() async {
  final budget=double.tryParse(_budget.text);
  if(_siteName.text.trim().isEmpty||budget==null||budget<=0){setState(()=>_message='Enter a site name and positive daily budget.');return;}
  final s=EnergySite(id:_id(),name:_siteName.text.trim(),type:'shared_residence',timezone:DateTime.now().timeZoneName,dailyBudgetKwh:budget,allocationPolicy:_policy);
  await _service.saveSite(s);await _service.audit(AllocationAudit(id:_id(),siteId:s.id,actor:'local-admin',action:'site-created',details:'Created ${s.name}',at:DateTime.now()));
  await _load();await _select(s);setState(()=>_message='Site saved locally.');
 }
 Future<void> _addRoom() async {
  final s=_selected;if(s==null||_roomName.text.trim().isEmpty)return;
  final room=EnergyRoom(id:_id(),siteId:s.id,name:_roomName.text.trim());
  await _service.saveRoom(room);await _service.audit(AllocationAudit(id:_id(),siteId:s.id,actor:'local-admin',action:'room-created',details:'Added ${room.name}',at:DateTime.now()));
  _roomName.clear();await _select(s);
 }
 @override Widget build(BuildContext context){
  final site=_selected;
  final allocations=site==null || _policy==AllocationPolicy.manual ? <RoomAllocation>[] : _service.allocate(site.copyWithPolicy(_policy),_rooms);
  final byId={for(final a in allocations)a.roomId:a.allocatedKwh};
  return Scaffold(appBar:AppBar(title:const Text('Shared Energy')),
   body:ListView(padding:const EdgeInsets.all(16),children:[
    const Text('Sites and room allocation',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
    if(_sites.isNotEmpty) DropdownButton<EnergySite>(isExpanded:true,value:site,items:_sites.map((s)=>DropdownMenuItem(value:s,child:Text(s.name))).toList(),onChanged:(s){if(s!=null)_select(s);}),
    TextField(controller:_siteName,decoration:const InputDecoration(labelText:'New site name')),
    TextField(controller:_budget,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Daily energy budget (kWh)')),
    DropdownButtonFormField<AllocationPolicy>(value:_policy,decoration:const InputDecoration(labelText:'Allocation policy'),items:AllocationPolicy.values.map((p)=>DropdownMenuItem(value:p,child:Text(p.name))).toList(),onChanged:(p){if(p!=null)setState(()=>_policy=p);}),
    FilledButton(onPressed:_createSite,child:const Text('Create site')),
    if(_message!=null)Text(_message!),
    if(site!=null)...[
     const Divider(),Text('Rooms in ${site.name}',style:Theme.of(context).textTheme.titleLarge),
     TextField(controller:_roomName,decoration:const InputDecoration(labelText:'Room name')),
     OutlinedButton(onPressed:_addRoom,child:const Text('Add room')),
     ..._rooms.map((r)=>Card(child:ListTile(title:Text(r.name),subtitle:Text(_policy==AllocationPolicy.manual ? 'Manual allocation requires admin approval' : 'Allocation: ${(byId[r.id]??0).toStringAsFixed(2)} kWh/day'),trailing:Text(_policy.name)))),
     const Text('Room consumption is not inferred from the site meter. Add certified room meters before classifying any reading as measured.'),
    ]
   ]));
 }
}
extension on EnergySite { EnergySite copyWithPolicy(AllocationPolicy p)=>EnergySite(id:id,name:name,type:type,timezone:timezone,dailyBudgetKwh:dailyBudgetKwh,allocationPolicy:p); }
