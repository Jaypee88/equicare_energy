import 'package:equicare_energy/core/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/models.dart';
import '../providers/energy_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _capCtrl;
  late TextEditingController _urlCtrl;
  late TextEditingController _latCtrl;
  late TextEditingController _lonCtrl;
  late TextEditingController _reserveCtrl;

  @override
  void initState() {
    super.initState();
    final p = context.read<EnergyProvider>();
    _capCtrl = TextEditingController(text: p.batteryCapacityWh.toString());
    _urlCtrl = TextEditingController(text: p.esp32BaseUrl);
    _latCtrl = TextEditingController(text: p.siteLatitude.toString());
    _lonCtrl = TextEditingController(text: p.siteLongitude.toString());
    _reserveCtrl = TextEditingController(text: p.reservePercent.toString());
  }

  @override
  void dispose() {
    _capCtrl.dispose(); _urlCtrl.dispose(); _latCtrl.dispose(); _lonCtrl.dispose(); _reserveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<EnergyProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---- Appearance ----
          const Text(
            'Appearance',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('Light'),
                icon: Icon(Icons.light_mode_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Dark'),
                icon: Icon(Icons.dark_mode_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('Auto'),
                icon: Icon(Icons.brightness_auto_outlined),
              ),
            ],
            selected: {context.watch<ThemeController>().mode},
            onSelectionChanged: (s) =>
                context.read<ThemeController>().setMode(s.first),
          ),
          const SizedBox(height: 24),
          // ---- Data source ----
          const Text(
            'Data source',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SegmentedButton<DataSourceType>(
            segments: const [
              ButtonSegment(
                value: DataSourceType.simulator,
                label: Text('Simulator'),
                icon: Icon(Icons.science_outlined),
              ),
              ButtonSegment(
                value: DataSourceType.esp32,
                label: Text('ESP32'),
                icon: Icon(Icons.memory),
              ),
            ],
            selected: {p.sourceType},
            onSelectionChanged: (s) => p.setSourceType(s.first),
          ),
          if (p.sourceType == DataSourceType.esp32) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _urlCtrl,
              decoration: const InputDecoration(
                labelText: 'ESP32 base URL',
                hintText: 'http://equicare.local',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => p.setEsp32BaseUrl(_urlCtrl.text.trim()),
              child: const Text('Save URL & reconnect'),
            ),
          ],

          const SizedBox(height: 24),

          // ---- Battery ----
          const Text(
            'Battery capacity (Wh)',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _capCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              suffixText: 'Wh',
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () async {
              final v = double.tryParse(_capCtrl.text);
              if (v != null && v > 0) {
                await p.setBatteryCapacity(v);
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Saved')));
                }
              }
            },
            child: const Text('Save capacity'),
          ),

          const SizedBox(height: 24),

          const SizedBox(height: 24),
          const Text('Protected battery reserve (%)', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(controller: _reserveCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(border: OutlineInputBorder(), suffixText: '%', helperText: 'Runtime calculations will preserve this reserve.')),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: () async {
            final v = double.tryParse(_reserveCtrl.text);
            if (v != null && v >= 0 && v < 100) { await p.setReservePercent(v); }
            else if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a reserve from 0 to below 100%.'))); }
          }, child: const Text('Save reserve')),
          const SizedBox(height: 24),
          const Text('Site location for solar forecast', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(controller: _latCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            decoration: const InputDecoration(labelText: 'Latitude', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(controller: _lonCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            decoration: const InputDecoration(labelText: 'Longitude', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          FilledButton(onPressed: () async {
            final lat = double.tryParse(_latCtrl.text), lon = double.tryParse(_lonCtrl.text);
            if (lat == null || lon == null || lat < -90 || lat > 90 || lon < -180 || lon > 180) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid latitude (-90 to 90) and longitude (-180 to 180).')));
              return;
            }
            await p.setSiteLocation(latitude: lat, longitude: lon);
          }, child: const Text('Save location & refresh forecast')),

          // ---- Forecast ----
          const Text('Forecast', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh solar forecast'),
            onPressed: () => p.refreshForecast(lat: p.siteLatitude, lon: p.siteLongitude),
          ),
          const SizedBox(height: 8),
          Text(
            'Last update: ${formatDateTime(p.lastSolarFetch)} (${formatAge(p.lastSolarFetch)})',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
          ),
          if (p.offline)
            Text(
              'Offline — using cached values',
              style: TextStyle(
                color: severityColors(context, Severity.warning).fg,
                fontSize: 12,
              ),
            ),

          const SizedBox(height: 24),

          // ---- Debug (hidden in a tile) ----
          if (p.sourceType == DataSourceType.simulator) ...[
            const Text(
              'Demo controls (simulator only)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => p.debugForceBattery(12),
                  child: const Text('Force 12% battery'),
                ),
                OutlinedButton(
                  onPressed: () => p.debugForceBattery(75),
                  child: const Text('Reset battery 75%'),
                ),
                OutlinedButton(
                  onPressed: () => p.debugForceLoad(1500),
                  child: const Text('Spike load 1500W'),
                ),
              ],
            ),
          ],

          const SizedBox(height: 32),
          Center(
            child: Text(
              'EquiCare Energy v0.1',
              style: TextStyle(
                fontSize: 11,
                color: scheme.onSurfaceVariant.withOpacity(0.6),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
