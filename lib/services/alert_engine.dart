import '../models/models.dart';

class AlertEngine {
  List<Alert> evaluate({
    required double batteryPercent,
    required double currentLoadW,
    required double baselineLoadW,
    required double runtimeHours,
    required double criticalPercent,
    required double lowPercent,
  }) {
    final alerts = <Alert>[];

    if (batteryPercent < criticalPercent) {
      final runtimeText = (!runtimeHours.isFinite || runtimeHours <= 0)
          ? 'Turn off non-essential devices.'
          : 'About ${runtimeHours.toStringAsFixed(1)}h left. Turn off non-essential devices.';
      alerts.add(Alert(Severity.critical, 'Low battery', runtimeText));
    } else if (batteryPercent < lowPercent) {
      alerts.add(
        Alert(
          Severity.warning,
          'Battery getting low',
          'Consider reducing usage soon.',
        ),
      );
    }

    // High consumption check
    if (baselineLoadW > 0 && currentLoadW > baselineLoadW * 1.5) {
      final pct = ((currentLoadW / baselineLoadW - 1) * 100).round();
      alerts.add(
        Alert(
          Severity.warning,
          'High consumption',
          'Usage is $pct% above your normal level.',
        ),
      );
    }
    return alerts;
  }

  List<String> recommendations({
    required double batteryPercent,
    required double solarW,
    required double loadW,
  }) {
    final recs = <String>[];

    // 1. If battery is low AND solar isn't covering it, tell them to wait
    if (batteryPercent < 20 && solarW < loadW) {
      recs.add('Postpone heavy loads (ironing, water pumping) until sunrise.');
      recs.add('Switch off unused lights and devices.');
    }

    // 2. If solar IS covering the load, tell them it's a good time to use power
    if (solarW > loadW) {
      recs.add(
        'Good time to run high-power tasks — solar is covering the load.',
      );
    }
    // 3. Only tell them to use stored energy if solar is NOT covering the load, but battery is full
    else if (batteryPercent >= 95) {
      recs.add('Battery nearly full — consider using stored energy.');
    }

    return recs;
  }
}
