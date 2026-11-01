import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../models/models.dart';
import '../providers/energy_provider.dart';
import '../widgets/alert_tile.dart';
import '../widgets/battery_gauge.dart';
import '../widgets/consumption_chart.dart';
import '../widgets/metric_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // ---------------- Status strip ----------------

  ({IconData icon, String label, Color fg, Color bg}) _status(
    EnergyProvider p,
    BuildContext context,
  ) {
    if (p.batteryPercent < p.criticalBatteryPercent) {
      final c = severityColors(context, Severity.critical);
      return (
        icon: Icons.error_outline,
        label:
            'Low battery — ${p.batteryPercent.round()}% • turn off non-essential devices',
        fg: c.fg,
        bg: c.bg,
      );
    }
    if (p.batteryPercent < p.lowBatteryPercent) {
      final c = severityColors(context, Severity.warning);
      return (
        icon: Icons.warning_amber,
        label: 'Battery getting low — ${p.batteryPercent.round()}%',
        fg: c.fg,
        bg: c.bg,
      );
    }

    final net = p.solarInputW - p.currentLoadW;
    if (net > 50) {
      final c = successBanner(context);
      return (
        icon: Icons.arrow_upward,
        label:
            'Charging • +${net.toStringAsFixed(0)} W surplus — good time for heavy loads',
        fg: c.fg,
        bg: c.bg,
      );
    }
    if (net < -50) {
      final c = severityColors(context, Severity.critical);
      return (
        icon: Icons.arrow_downward,
        label: 'Discharging • ${net.toStringAsFixed(0)} W — battery draining',
        fg: c.fg,
        bg: c.bg,
      );
    }

    // Neutral: use surface colours so it blends cleanly in both modes.
    final scheme = Theme.of(context).colorScheme;
    return (
      icon: Icons.remove,
      label: 'Neutral • solar ≈ load',
      fg: scheme.onSurfaceVariant,
      bg: scheme.surfaceContainerHighest,
    );
  }

  // ---------------- Charge-time label ----------------

  String _chargeTimeLabel(EnergyProvider p) {
    if (p.batteryFull) return 'Full';

    // If there is no solar right now, don't show the forecast countdown.
    if (p.solarInputW <= 5) return 'No solar';

    final hours = p.chargeHours;
    if (hours.isFinite) return formatHours(hours);
    return p.chargeBlockReason ?? 'Unavailable';
  }

  // ---------------- Runtime severity colour ----------------

  Color? _runtimeColor(double hours) {
    if (!hours.isFinite) return Colors.grey;
    if (hours < 1) return Colors.red;
    if (hours < 3) return Colors.orange;
    return null;
  }

  // ---------------- Charge-time colour ----------------

  Color? _chargeColor(EnergyProvider p) {
    if (p.batteryFull) return Colors.green;
    // If we are not currently getting any solar, don't show "green/charging" yet.
    if (p.solarInputW <= 5) return Colors.grey;
    if (p.chargeHours.isFinite) return Colors.green;
    return Colors.grey;
  }

  // ---------------- Build ----------------

  @override
  Widget build(BuildContext context) {
    final p = context.watch<EnergyProvider>();
    final status = _status(p, context);
    final loads = p.history.map((r) => r.loadW).toList();
    final scheme = Theme.of(context).colorScheme;
    final accent = accentBanner(context);
    final success = successBanner(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('EquiCare Energy'),
        actions: [
          IconButton(icon: const Icon(Icons.balance_outlined), tooltip: 'Energy equity & resilience', onPressed: () => Navigator.pushNamed(context, '/equity')),
          IconButton(icon: const Icon(Icons.groups_outlined), tooltip: 'Shared Energy sites and rooms', onPressed: () => Navigator.pushNamed(context, '/shared-energy')),
          IconButton(icon: const Icon(Icons.notifications_outlined), tooltip: 'Alerts', onPressed: () => Navigator.pushNamed(context, '/alerts')),
          IconButton(icon: const Icon(Icons.wb_sunny_outlined), tooltip: 'Solar forecast', onPressed: () => Navigator.pushNamed(context, '/forecast')),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.pushNamed(context, '/history'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => p.refreshForecast(lat: 6.5244, lon: 3.3792),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ---- DEMO MODE BADGE ----
            if (p.sourceType == DataSourceType.simulator) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withOpacity(0.5)),
                ),
                child: const Text(
                  'DEMO MODE — Data is simulated',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ---- (1) Status strip ----
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: status.bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: status.fg.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(status.icon, color: status.fg, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      status.label,
                      style: TextStyle(
                        color: status.fg,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ---- (4) Pinned top recommendation ----
            if (p.recommendations.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accent.bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accent.fg.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.tips_and_updates_outlined,
                        color: accent.fg,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          p.recommendations.first,
                          style: TextStyle(color: accent.fg, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ---- Gauge + Usable Energy subtitle ----
            Center(
              child: Column(
                children: [
                  BatteryGauge(percent: p.batteryPercent),
                  const SizedBox(height: 8),
                  Text(
                    '${formatWh(p.usableEnergyWh)} usable',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ---- (2) Coloured metric cards ----
            Row(
              children: [
                Expanded(
                  child: MetricCard(
                    label: 'Runtime',
                    value: formatHours(p.runtimeHours),
                    icon: Icons.timer_outlined,
                    valueColor: _runtimeColor(p.runtimeHours),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricCard(
                    label: 'Charge time',
                    value: _chargeTimeLabel(p),
                    icon: Icons.bolt,
                    valueColor: _chargeColor(p),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MetricCard(
                    label: 'Load',
                    value: formatW(p.currentLoadW),
                    icon: Icons.power,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricCard(
                    label: 'Solar',
                    value: formatW(p.solarInputW),
                    icon: Icons.wb_sunny_outlined,
                    valueColor: p.solarInputW > 0
                        ? Colors.amber.shade700
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ---- (3) Chart with subtitle ----
            const Text(
              'Consumption (recent)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ConsumptionChart(records: p.history),
                    const SizedBox(height: 8),
                    Text(
                      formatChartSubtitle(loads),
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ---- (5) Alerts — with empty state ----
            if (p.alerts.isNotEmpty) ...[
              const Text(
                'Alerts',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...p.alerts.map((a) => AlertTile(alert: a)),
            ] else ...[
              Card(
                color: success.bg,
                child: ListTile(
                  leading: Icon(Icons.check_circle_outline, color: success.fg),
                  title: Text(
                    'No alerts — battery health good',
                    style: TextStyle(
                      color: success.fg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Runtime ${formatHours(p.runtimeHours)} at current load',
                    style: TextStyle(color: success.fg.withOpacity(0.85)),
                  ),
                ),
              ),
            ],

            // ---- Full recommendation list (if more than one) ----
            if (p.recommendations.length > 1) ...[
              const SizedBox(height: 16),
              const Text(
                'More recommendations',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final r in p.recommendations.skip(1))
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.tips_and_updates_outlined,
                                size: 18,
                                color: accent.fg,
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(r)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],

            // ---- Offline badge ----
            if (p.offline)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'Offline — showing cached solar data. Last update: ${formatDateTime(p.lastSolarFetch)}',
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // ---- Model check card ----
            Card(
              child: ListTile(
                leading: const Icon(Icons.insights),
                title: const Text('Model check'),
                subtitle: Text(
                  'ML MAE ${p.mlMAE.toStringAsFixed(1)} W  •  '
                  'Baseline ${p.baselineMAE.toStringAsFixed(1)} W  •  '
                  '${p.sampleCount} samples',
                ),
                onTap: () => Navigator.pushNamed(context, '/model'),
              ),
            ),

            // ---- (6) Footer ----
            const SizedBox(height: 24),
            Center(
              child: Text(
                'EquiCare Energy v0.1  •  Offline-first  •  '
                'Last forecast: ${formatAge(p.lastSolarFetch)}',
                style: TextStyle(
                  fontSize: 11,
                  color: scheme.onSurfaceVariant.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
