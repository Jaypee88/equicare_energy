import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';

class StorageService {
  static const _historyBox = 'history';
  static const _cacheBox = 'cache';
  static const _modelBox = 'model';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_historyBox);
    await Hive.openBox(_cacheBox);
    await Hive.openBox(_modelBox);
  }

  static Box get history => Hive.box(_historyBox);
  static Box get cache => Hive.box(_cacheBox);
  static Box get model => Hive.box(_modelBox);

  static Future<void> appendRecord(ConsumptionRecord r) async {
    final box = history;
    await box.add(r.toMap());
    if (box.length > 500) await box.deleteAt(0);
  }

  static List<ConsumptionRecord> recent({int limit = 200}) {
    final box = history;
    final start = box.length > limit ? box.length - limit : 0;
    return [for (var i = start; i < box.length; i++)
      ConsumptionRecord.fromMap(Map<String, dynamic>.from(box.getAt(i) as Map))];
  }

  static Future<void> cacheSolarJson(String json) => cache.put('solar_json', json);
  static String? getCachedSolarJson() => cache.get('solar_json') as String?;
  static Future<void> saveModelJson(String json) => model.put('predictor', json);
  static String? loadModelJson() => model.get('predictor') as String?;

  static Future<void> saveForecast(List<WeatherForecast> forecast, {required DateTime fetchedAt}) async {
    await cache.put('forecast', jsonEncode(forecast.map((f) => f.toMap()).toList()));
    await cache.put('forecast_fetched_at', fetchedAt.toIso8601String());
  }

  static List<WeatherForecast> loadForecast() {
    final raw = cache.get('forecast') as String?;
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => WeatherForecast.fromMap(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) { return []; }
  }

  static DateTime? forecastFetchedAt() {
    final raw = cache.get('forecast_fetched_at') as String?;
    return raw == null ? null : DateTime.tryParse(raw);
  }
}
