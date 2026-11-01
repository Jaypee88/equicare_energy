import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/energy_provider.dart';
import '../widgets/alert_tile.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.watch<EnergyProvider>();
    final items = [...p.alerts]..sort((a,b) => b.at.compareTo(a.at));
    return Scaffold(appBar: AppBar(title: const Text('Energy alerts')),
      body: items.isEmpty
        ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.verified_outlined, size: 48), SizedBox(height: 12),
            Text('No active alerts', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text('Alerts appear when battery reserve, load or system conditions need attention.'),
          ])))
        : ListView(padding: const EdgeInsets.all(16), children: [
            Text('${items.length} active alert(s)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...items.map((a) => AlertTile(alert: a)),
            const SizedBox(height: 16),
            const Text('Recommendations are advisory. Verify site conditions before changing loads; never disconnect critical medical equipment.'),
          ]));
  }
}