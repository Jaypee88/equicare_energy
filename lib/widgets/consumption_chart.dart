import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';

class ConsumptionChart extends StatelessWidget {
  final List<ConsumptionRecord> records;
  const ConsumptionChart({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return SizedBox(
        height: 160,
        child: Center(
          child: Text(
            'No data yet',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final spots = <FlSpot>[
      for (var i = 0; i < records.length; i++)
        FlSpot(i.toDouble(), records[i].loadW),
    ];

    // Line colour: brighter teal in dark mode for contrast against near-black,
    // muted indigo in light mode for a calm appearance on white.
    final lineColor = isDark ? Colors.teal.shade300 : Colors.indigo;

    return SizedBox(
      height: 160,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              dotData: const FlDotData(show: false),
              color: lineColor,
              barWidth: 2,
              belowBarData: BarAreaData(
                show: true,
                color: lineColor.withOpacity(isDark ? 0.12 : 0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
