import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/utils.dart';
import '../providers/energy_provider.dart';
import '../widgets/consumption_chart.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<EnergyProvider>();
    final recs = p.history;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: recs.isEmpty
          ? Center(
              child: Text(
                'No history yet',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Consumption',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: ConsumptionChart(records: recs),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Recent samples',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ...recs.reversed
                    .take(30)
                    .map(
                      (r) => Card(
                        child: ListTile(
                          dense: true,
                          title: Text(
                            '${formatW(r.loadW)}  •  ${r.batteryPercent.toStringAsFixed(0)}%',
                          ),
                          trailing: Text(
                            formatTime(r.time),
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        ),
                      ),
                    ),
              ],
            ),
    );
  }
}
