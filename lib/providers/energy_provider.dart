import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../models/models.dart';
import '../services/alert_engine.dart';
import '../services/energy_calculator.dart';
import '../services/energy_data_source.dart';
import '../services/http_source.dart';
import '../services/model_trainer.dart';
import '../services/notification_service.dart';
import '../services/predictor.dart';
import '../services/simulated_source.dart';
import '../services/solar_service.dart';
import '../services/storage_service.dart';

enum DataSourceType { simulator, esp32 }

class EnergyProvider extends ChangeNotifier {
  final _alerts = AlertEngine();
  final _solar = SolarService();
  final _predictor = Predictor();

  StreamSubscription<EnergyReading>? _sub;
  EnergyDataSource? _source;
  DataSourceType _sourceType = DataSourceType.simulator;
  String _esp32BaseUrl = 'http://equicare.local';

  // Configurable Setup
  double batteryCapacityWh = AppConfig.defaultBatteryCapacityWh;
  double panelCapacityWp = AppConfig.defaultPanelCapacityWp;
  double criticalBatteryPercent = AppConfig.criticalBatteryPercent;
  double reservePercent = 10;
  double siteLatitude = 6.5244;
  double siteLongitude = 3.3792;
  double lowBatteryPercent = AppConfig.lowBatteryPercent;
  bool hasCompletedOnboarding = false;

  // Live state
  double batteryPercent = 72;
  double currentLoadW = 300;
  double solarInputW = 0;
  DateTime lastSolarFetch = DateTime.now();

  // History / derived
  List<ConsumptionRecord> history = [];
  List<WeatherForecast> forecast = [];
  List<Alert> alerts = [];
  List<String> recommendations = [];
  String? lastError;
  bool offline = false;

  // Model comparison
  double mlMAE = 0;
  double baselineMAE = 0;
  int sampleCount = 0;
  double? lastPredictionW;
  double? lastBaselineW;
  double? lastActualW;

  // Training state
  TrainingResult? lastTraining;
  bool training = false;
  bool get isTrained => _predictor.isTrained;

  // Getters
  DataSourceType get sourceType => _sourceType;
  String get esp32BaseUrl => _esp32BaseUrl;
  Predictor get predictor => _predictor;
  TrainingResult? get lastTrainingResult => lastTraining;
  bool get isTraining => training;

  double get runtimeHours => EnergyCalculator.estimateRuntimeHours(
    batteryPercent: batteryPercent,
    batteryCapacityWh: batteryCapacityWh,
    currentLoadW: currentLoadW,
    reservePercent: reservePercent,
    efficiency: AppConfig.systemEfficiency,
  );

  double get usableEnergyWh => batteryCapacityWh * (batteryPercent / 100);

  bool get batteryFull => batteryPercent >= 99.5;
  bool get sunUp => solarInputW > 5;
  bool get netCharging => solarInputW > currentLoadW;

  double get chargeHours {
    if (batteryFull) return 0;
    final neededWh = batteryCapacityWh * ((100 - batteryPercent) / 100);
    if (neededWh <= 0) return 0;

    final now = DateTime.now();
    final netNow = solarInputW - currentLoadW;
    double accumulatedWh = 0;
    if (netNow > 0) {
      accumulatedWh = netNow;
      if (accumulatedWh >= neededWh) return neededWh / netNow;
    }

    final futureHours = forecast.where((f) => f.time.isAfter(now)).toList()
      ..sort((a, b) => a.time.compareTo(b.time));

    if (futureHours.isEmpty) {
      return netNow > 0 ? neededWh / netNow : double.infinity;
    }

    double lastHourOffset = 1.0;
    for (final f in futureHours) {
      final offsetHours = f.time.difference(now).inMinutes / 60.0;
      if (offsetHours > 48) break;
      if (offsetHours <= lastHourOffset) continue;

      final predictedLoad = _predictor.predictNextHourW(
        hourOfDay: f.time.hour,
        dayOfWeek: f.time.weekday,
        avg3hW: currentLoadW,
      );
      final net = f.estimatedSolarW - predictedLoad;
      if (net <= 0) {
        lastHourOffset = offsetHours;
        continue;
      }

      accumulatedWh += net;
      if (accumulatedWh >= neededWh) {
        final remaining = neededWh - (accumulatedWh - net);
        return offsetHours - 1 + (remaining / net);
      }
      lastHourOffset = offsetHours;
    }
    return double.infinity;
  }

  String? get chargeBlockReason {
    if (chargeHours.isFinite) return null;
    if (!sunUp) return forecast.isEmpty ? 'No forecast' : 'Sun below horizon';
    if (!netCharging) return 'Solar < load';
    return 'Forecast insufficient';
  }

  double get baselineLoadW {
    if (history.length < 3) return currentLoadW;
    final last3 = history.sublist(history.length - 3);
    return last3.map((r) => r.loadW).reduce((a, b) => a + b) / 3;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    batteryCapacityWh =
        prefs.getDouble('batteryCapacityWh') ??
        AppConfig.defaultBatteryCapacityWh;
    panelCapacityWp =
        prefs.getDouble('panelCapacityWp') ?? AppConfig.defaultPanelCapacityWp;
    criticalBatteryPercent =
        prefs.getDouble('criticalBatteryPercent') ??
        AppConfig.criticalBatteryPercent;
    reservePercent = prefs.getDouble('reservePercent') ?? 10;
    siteLatitude = prefs.getDouble('siteLatitude') ?? 6.5244;
    siteLongitude = prefs.getDouble('siteLongitude') ?? 3.3792;
    lowBatteryPercent =
        prefs.getDouble('lowBatteryPercent') ?? AppConfig.lowBatteryPercent;
    hasCompletedOnboarding = prefs.getBool('hasCompletedOnboarding') ?? false;

    _esp32BaseUrl = prefs.getString('esp32BaseUrl') ?? _esp32BaseUrl;
    final typeName = prefs.getString('sourceType') ?? 'simulator';
    _sourceType = typeName == 'esp32'
        ? DataSourceType.esp32
        : DataSourceType.simulator;

    history = StorageService.recent(limit: 120);
    if (history.isNotEmpty) {
      batteryPercent = history.last.batteryPercent;
      currentLoadW = history.last.loadW;
    }

    final savedModel = StorageService.loadModelJson();
    if (savedModel != null) {
      try {
        _predictor.loadFromJson(jsonDecode(savedModel) as Map<String, dynamic>);
      } catch (_) {}
    }

    forecast = StorageService.loadForecast();
    lastSolarFetch = StorageService.forecastFetchedAt() ?? DateTime.fromMillisecondsSinceEpoch(0);
    await _switchSource(_sourceType, restart: false);
    unawaited(refreshForecast(lat: siteLatitude, lon: siteLongitude));
  }

  Future<void> _switchSource(DataSourceType type, {bool restart = true}) async {
    await _sub?.cancel();
    await _source?.close();
    _sourceType = type;
    _source = type == DataSourceType.esp32
        ? HttpEnergyDataSource(baseUrl: _esp32BaseUrl)
        : SimulatedSource();
    _sub = _source!.readings().listen(_onReading);
    if (restart) notifyListeners();
  }

  void _onReading(EnergyReading r) {
    offline = false;
    batteryPercent = r.batteryPercent;
    currentLoadW = r.loadW;
    solarInputW = r.solarW;

    final rec = ConsumptionRecord(r.time, r.loadW, r.batteryPercent);
    history.add(rec);
    if (history.length > 200) history.removeAt(0);
    StorageService.appendRecord(rec);

    _evaluateAlerts();
    _updateModelScore();
    notifyListeners();
  }

  void _evaluateAlerts() {
    final newAlerts = _alerts.evaluate(
      batteryPercent: batteryPercent,
      currentLoadW: currentLoadW,
      baselineLoadW: baselineLoadW,
      runtimeHours: runtimeHours,
      criticalPercent: criticalBatteryPercent,
      lowPercent: lowBatteryPercent,
    );

    // Trigger push notifications for new Critical alerts
    for (final alert in newAlerts) {
      if (alert.severity == Severity.critical) {
        NotificationService.showAlert(alert);
      }
    }

    alerts = newAlerts;
    recommendations = _alerts.recommendations(
      batteryPercent: batteryPercent,
      solarW: solarInputW,
      loadW: currentLoadW,
    );
  }

  void _updateModelScore() {
    if (history.length < 6) return;
    final prev = history[history.length - 2];
    final actual = currentLoadW;
    final avg3 = _avgLast(3, beforeLast: true);
    final pred = _predictor.predictNextHourW(
      hourOfDay: prev.time.hour,
      dayOfWeek: prev.time.weekday,
      avg3hW: avg3,
    );
    final base = _predictor.baselineNextHourW(avg3);

    final n = sampleCount;
    mlMAE = (mlMAE * n + (pred - actual).abs()) / (n + 1);
    baselineMAE = (baselineMAE * n + (base - actual).abs()) / (n + 1);
    sampleCount = n + 1;

    lastPredictionW = pred;
    lastBaselineW = base;
    lastActualW = actual;
  }

  double _avgLast(int k, {bool beforeLast = false}) {
    final end = history.length - (beforeLast ? 1 : 0);
    final start = max(0, end - k);
    if (start >= end) return currentLoadW;
    final slice = history.sublist(start, end);
    return slice.map((r) => r.loadW).reduce((a, b) => a + b) / slice.length;
  }

  Future<void> refreshForecast({
    required double lat,
    required double lon,
  }) async {
    try {
      offline = false;
      forecast = await _solar.fetchForecast(lat: lat, lon: lon, panelCapacityWp: panelCapacityWp);
      lastSolarFetch = DateTime.now();
      await StorageService.saveForecast(forecast, fetchedAt: lastSolarFetch);
      lastError = null;
    } catch (e) {
      offline = true;
      lastError = e.toString();
      // Keep the last successful forecast in memory; if none is loaded, restore disk cache.
      if (forecast.isEmpty) forecast = StorageService.loadForecast();
      lastSolarFetch = StorageService.forecastFetchedAt() ?? lastSolarFetch;
    }
    notifyListeners();
  }

  Future<void> setSiteLocation({required double latitude, required double longitude}) async {
    if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
      throw ArgumentError('Latitude or longitude is outside valid bounds.');
    }
    siteLatitude = latitude;
    siteLongitude = longitude;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('siteLatitude', latitude);
    await prefs.setDouble('siteLongitude', longitude);
    await refreshForecast(lat: latitude, lon: longitude);
  }

  Future<void> setReservePercent(double value) async {
    if (value < 0 || value >= 100) throw ArgumentError('Reserve must be from 0 to below 100%.');
    reservePercent = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('reservePercent', value);
    notifyListeners();
  }

  // Settings Setters
  Future<void> setBatteryCapacity(double wh) async {
    batteryCapacityWh = wh;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('batteryCapacityWh', wh);
    notifyListeners();
  }

  Future<void> setPanelCapacity(double wp) async {
    panelCapacityWp = wp;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('panelCapacityWp', wp);
    notifyListeners();
  }

  Future<void> setAlertThresholds(double low, double critical) async {
    lowBatteryPercent = low;
    criticalBatteryPercent = critical;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('lowBatteryPercent', low);
    await prefs.setDouble('criticalBatteryPercent', critical);
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    hasCompletedOnboarding = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasCompletedOnboarding', true);
    notifyListeners();
  }

  Future<void> setSourceType(DataSourceType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'sourceType',
      type == DataSourceType.esp32 ? 'esp32' : 'simulator',
    );
    await _switchSource(type);
  }

  Future<void> setEsp32BaseUrl(String url) async {
    _esp32BaseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('esp32BaseUrl', url);
    if (_sourceType == DataSourceType.esp32) {
      await _switchSource(DataSourceType.esp32);
    }
    notifyListeners();
  }

  Future<TrainingResult?> retrainModel() async {
    if (training) return lastTraining;
    training = true;
    notifyListeners();

    try {
      final allRecords = StorageService.recent(limit: 500);
      final trainer = ModelTrainer();
      final samples = trainer.buildSamples(allRecords);
      final result = trainer.fit(samples);

      if (result != null) {
        // Never replace the active model when it loses to the simple baseline.
        // The current trainer reports an in-sample comparison; a chronological
        // holdout should be added before treating this as production validation.
        lastTraining = result;
        mlMAE = result.trainMAE;
        baselineMAE = result.baselineMAE;
        sampleCount = result.samples;
        if (result.trainMAE < result.baselineMAE) {
          _predictor.applyWeights(result.weights, sampleCount: result.samples);
          await StorageService.saveModelJson(jsonEncode(_predictor.toJson()));
        }
      }
      return result;
    } finally {
      training = false;
      notifyListeners();
    }
  }

  Future<void> resetModel() async {
    _predictor.resetToDefaults();
    await StorageService.saveModelJson(jsonEncode(_predictor.toJson()));
    lastTraining = null;
    mlMAE = 0;
    baselineMAE = 0;
    sampleCount = 0;
    notifyListeners();
  }

  void debugForceBattery(double pct) {
    final s = _source;
    if (s is SimulatedSource) {
      s.forceBatteryPercent(pct);
      batteryPercent = pct;
      _evaluateAlerts();
      notifyListeners();
    }
  }

  void debugForceLoad(double w) {
    final s = _source;
    if (s is SimulatedSource) {
      s.forceLoadW(w);
      currentLoadW = w;
      _evaluateAlerts();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _source?.close();
    super.dispose();
  }
}
