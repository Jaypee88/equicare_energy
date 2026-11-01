import 'package:flutter/material.dart';
import '../services/energy_calculator.dart';

class EquityModesScreen extends StatefulWidget {
  const EquityModesScreen({super.key});
  @override
  State<EquityModesScreen> createState() => _EquityModesScreenState();
}

class _EquityModesScreenState extends State<EquityModesScreen> {
  int _mode = 1;
  double _batteryWh = 2400;
  double _batteryPct = 72;
  double _loadW = 650;
  double _flexW = 150;
  double _reservePct = 10;
  double _efficiency = .85;
  double _sharedBudgetKwh = 12;
  final List<double> _weights = [1, 1, 1, 1];
  final List<double> _demoUse = [1.8, 2.6, 1.2, 2.1];

  String _hours(double value) => value.isFinite ? '${value.toStringAsFixed(1)} h' : 'Not limited by load';

  @override
  Widget build(BuildContext context) {
    final autonomy = EnergyCalculator.estimateAutonomy(
      batteryPercent: _batteryPct, batteryCapacityWh: _batteryWh,
      currentLoadW: _loadW, flexibleLoadReductionW: _flexW,
      reservePercent: _reservePct, efficiency: _efficiency,
    );
    final totalWeight = _weights.fold<double>(0, (a,b) => a+b);
    final allocations = _weights.map((w) => _sharedBudgetKwh * w / totalWeight).toList();
    final ratios = List<double>.generate(4, (i) => _demoUse[i] / allocations[i]);
    final fairness = EnergyCalculator.jainsFairnessIndex(ratios);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Energy equity & resilience')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('Shared Energy'), icon: Icon(Icons.groups_outlined)),
            ButtonSegment(value: 1, label: Text('Critical Services'), icon: Icon(Icons.local_hospital_outlined)),
          ],
          selected: {_mode}, onSelectionChanged: (s) => setState(() => _mode = s.first),
        ),
        const SizedBox(height: 16),
        if (_mode == 1) ...[
          const Text('Critical Autonomy Countdown', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Scenario calculator only. Flexible-load reduction is a proposal for an authorised person to review; critical medical equipment is never switched off by this app.'),
          const SizedBox(height: 16),
          _slider('Battery capacity', _batteryWh, 500, 20000, (v) => setState(() => _batteryWh=v), suffix: ' Wh'),
          _slider('Battery state of charge', _batteryPct, 0, 100, (v) => setState(() => _batteryPct=v), suffix: '%'),
          _slider('Current facility load', _loadW, 50, 5000, (v) => setState(() => _loadW=v), suffix: ' W'),
          _slider('Proposed flexible-load reduction', _flexW, 0, _loadW, (v) => setState(() => _flexW=v), suffix: ' W'),
          _slider('Protected battery reserve', _reservePct, 0, 50, (v) => setState(() => _reservePct=v), suffix: '%'),
          _slider('System efficiency', _efficiency*100, 50, 100, (v) => setState(() => _efficiency=v/100), suffix: '%'),
          const SizedBox(height: 12),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Current load autonomy', style: TextStyle(color: scheme.onSurfaceVariant)),
            Text(_hours(autonomy.currentHours), style: const TextStyle(fontSize: 27, fontWeight: FontWeight.bold)),
            const Divider(),
            Text('If approved flexible loads are reduced', style: TextStyle(color: scheme.onSurfaceVariant)),
            Text(_hours(autonomy.reducedLoadHours), style: const TextStyle(fontSize: 27, fontWeight: FontWeight.bold)),
            Text('Potential extension: ${autonomy.extensionHours.toStringAsFixed(1)} hours', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600)),
          ]))),
          const Text('Assumptions: constant load, configured battery capacity, reserve and efficiency. Actual runtime varies with battery health, temperature, inverter limits and changing demand.'),
        ] else ...[
          const Text('Fair allocation planner', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
          const Text('Illustrative four-room demo. Consumption values below are simulated examples, not measured readings. Individual attribution requires a meter or smart plug per room.'),
          const SizedBox(height: 12),
          _slider('Daily energy budget', _sharedBudgetKwh, 1, 50, (v) => setState(() => _sharedBudgetKwh=v), suffix: ' kWh'),
          ...List.generate(4, (i) => Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Room ${i+1}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Allocation: ${allocations[i].toStringAsFixed(2)} kWh  •  Demo use: ${_demoUse[i].toStringAsFixed(1)} kWh'),
            Slider(value: _weights[i], min: .5, max: 2, divisions: 15, label: 'Weight ${_weights[i].toStringAsFixed(1)}', onChanged: (v) => setState(() => _weights[i]=v)),
          ])))),
          Card(child: ListTile(
            title: const Text('Jain fairness index'),
            subtitle: const Text('Calculated from demo consumption-to-allocation ratios. 1.0 indicates equal ratios; this is not a judgement of need or service quality.'),
            trailing: Text(fairness.toStringAsFixed(2), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          )),
          const Text('Allocation is weighted by the sliders. Production deployments should support equal, weighted, priority and administrator-approved manual policies, with an audit trail.'),
        ],
      ]),
    );
  }

  Widget _slider(String label, double value, double min, double max, ValueChanged<double> changed, {String suffix = ''}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('$label: ${value.toStringAsFixed(0)}$suffix'),
      Slider(value: value.clamp(min, max), min: min, max: max, onChanged: changed),
    ]);
  }
}
