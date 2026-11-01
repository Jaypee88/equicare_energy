import 'dart:async';
import 'dart:math';
import '../core/constants.dart';
import 'energy_data_source.dart';

/// Simulated off-grid solar installation.
///
/// ## Critical design point — internal simulated clock
///
/// Most bug reports against this file have been "battery drains to zero
/// and stays" or "solar is never above load". Both have the same cause:
/// **the simulator was sampling real wall-clock time on every tick**,
/// so if you opened the app at 8 PM, every tick evaluated the load and
/// solar curves at 8 PM — solar = 0, load = 500 W, battery drains one
/// hour's worth every tick until it reaches zero, then stays.
///
/// The fix: the simulator keeps its own [_simulatedHour] and advances it
/// by 1 per tick, independent of wall clock. Each tick genuinely moves
/// forward through a simulated day.
///
/// ## Calibration (verified against daily energy integrals)
///
/// - Load: 110–130 W base + 380 W bell at 19:00 → ~4,785 Wh/day
/// - Solar: 400 Wp × 2.6 × 0.75 × sine-bell → ~5,363 Wh/day
/// - Ratio: 1.12 → +578 Wh/day = +24% of battery per day
/// - Solar > load: ~9 simulated hours/day (07:00 → 16:00)
/// - Battery cycle: ~40% → ~80% → ~40%, stable across days
class SimulatedSource implements EnergyDataSource {
  SimulatedSource({
    this.tickPeriod = const Duration(seconds: 5),
    double startHour = 6.0,
    double startBatteryPercent = 55.0,
  }) : _simulatedHour = startHour,
       _batteryPercent = startBatteryPercent;

  /// Real time between ticks. Each tick = 1 simulated hour.
  /// 5 s = a day in 2 minutes. 2 s = a day in 48 seconds.
  final Duration tickPeriod;

  final _controller = StreamController<EnergyReading>.broadcast();
  Timer? _timer;
  final _rng = Random();

  /// THE FIX: internal simulated clock, independent of wall time.
  /// Advances by 1.0 per tick, wraps at 24.
  double _simulatedHour;

  double _batteryPercent;
  double _loadW = 150;

  // ----- Load calibration -----
  static const double _baseLoadMinW = 110;
  static const double _baseLoadMaxW = 130;
  static const double _eveningPeakW = 380;
  static const double _eveningPeakHour = 19;
  static const double _eveningPeakWidth = 8;

  // ----- Solar calibration -----
  static const double _panelPeakMultiplier = 2.6;
  static const double _cloudMin = 0.70;
  static const double _cloudMax = 1.10;
  static const double _sunriseHour = 6;
  static const double _sunsetHour = 18;

  // ---------------------------------------------------------------------

  @override
  Stream<EnergyReading> readings() {
    _timer ??= Timer.periodic(tickPeriod, (_) => _tick());
    return _controller.stream;
  }

  void _tick() {
    final hour = _simulatedHour;

    // ---------- Load ----------
    final baseLoad =
        _baseLoadMinW + _rng.nextDouble() * (_baseLoadMaxW - _baseLoadMinW);
    final eveningBell = exp(
      -pow(hour - _eveningPeakHour, 2) / _eveningPeakWidth,
    );
    final targetLoad = baseLoad + _eveningPeakW * eveningBell;
    _loadW = _loadW * 0.6 + targetLoad * 0.4; // smooth

    // ---------- Solar ----------
    double solarW = 0;
    if (hour >= _sunriseHour && hour <= _sunsetHour) {
      final bell = sin(
        (hour - _sunriseHour) / (_sunsetHour - _sunriseHour) * pi,
      );
      final rawPeak = AppConfig.defaultPanelCapacityWp * _panelPeakMultiplier;
      solarW = rawPeak * bell * AppConfig.systemEfficiency;
      solarW *= _cloudMin + _rng.nextDouble() * (_cloudMax - _cloudMin);
      solarW = solarW.clamp(0.0, double.infinity);
    }

    // ---------- Battery (one simulated hour of net energy) ----------
    final netWh = solarW - _loadW;
    _batteryPercent += netWh / AppConfig.defaultBatteryCapacityWh * 100;
    _batteryPercent = _batteryPercent.clamp(0.0, 100.0);

    // ---------- Emit ----------
    // The EnergyReading carries the *simulated* time, not real time,
    // so downstream code sees a coherent clock.
    final baseDate = DateTime.now();
    final simulatedDate = DateTime(
      baseDate.year,
      baseDate.month,
      baseDate.day,
    ).add(Duration(minutes: (hour * 60).round()));

    _controller.add(
      EnergyReading(simulatedDate, _batteryPercent, _loadW, solarW),
    );

    // ---------- Advance simulated clock ----------
    _simulatedHour += 1.0;
    if (_simulatedHour >= 24) _simulatedHour -= 24;
  }

  // ---------- Demo helpers ----------

  void forceBatteryPercent(double pct) {
    _batteryPercent = pct.clamp(0.0, 100.0);
  }

  void forceLoadW(double w) {
    _loadW = w;
  }

  /// Jump the internal clock to a specific hour — useful for demos.
  void setSimulatedHour(double hour) {
    _simulatedHour = hour % 24;
  }

  @override
  Future<void> close() async {
    _timer?.cancel();
    await _controller.close();
  }
}
