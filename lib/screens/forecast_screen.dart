import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/energy_provider.dart';

class ForecastScreen extends StatelessWidget {
  const ForecastScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.watch<EnergyProvider>();
    final rows = [...p.forecast]..sort((a,b) => a.time.compareTo(b.time));
    return Scaffold(appBar: AppBar(title: const Text('Solar forecast'), actions: [
      IconButton(tooltip: 'Refresh', icon: const Icon(Icons.refresh), onPressed: () => p.refreshForecast(lat: p.siteLatitude, lon: p.siteLongitude)),
    ]), body: ListView(padding: const EdgeInsets.all(16), children: [
      Card(child: ListTile(leading: const Icon(Icons.cloud_outlined), title: Text(p.offline ? 'Offline / cached status' : 'Open-Meteo forecast'), subtitle: Text('Last successful refresh: ${p.lastSolarFetch.toLocal()}'))),
      const Text('Forecast values are estimates, not meter readings. Actual solar generation depends on panel orientation, shading, temperature and system losses.'),
      const SizedBox(height: 12),
      if (rows.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('No forecast data available. Connect to the internet and refresh.')),
      ...rows.take(48).map((f) => Card(child: ListTile(
        leading: const Icon(Icons.wb_sunny_outlined),
        title: Text('${f.time.toLocal()}'),
        subtitle: Text('Solar irradiance: ${f.irradianceWm2.toStringAsFixed(0)} W/m²'),
        trailing: Text('${f.estimatedSolarW.toStringAsFixed(0)} W est.'),
      ))),
    ]));
  }
}