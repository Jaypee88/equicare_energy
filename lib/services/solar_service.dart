import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/models.dart';

class SolarService {
  static const _base = 'https://api.open-meteo.com/v1/forecast';

  Future<List<WeatherForecast>> fetchForecast({
    required double lat,
    required double lon,
  }) async {
    final uri = Uri.parse(_base).replace(
      queryParameters: {
        'latitude': '$lat',
        'longitude': '$lon',
        'hourly': 'shortwave_radiation',
        'forecast_days': '2',
        'timezone': 'auto',
      },
    );

    final res = await http.get(uri).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) {
      throw Exception('Weather fetch failed: ${res.statusCode}');
    }

    final data = jsonDecode(res.body);
    final times = List<String>.from(data['hourly']['time']);
    final radRaw = List<dynamic>.from(data['hourly']['shortwave_radiation']);
    final radiation = radRaw
        .map((v) => (v == null ? 0.0 : (v as num).toDouble()))
        .toList();

    return List.generate(times.length, (i) {
      final wm2 = radiation[i];
      // Rough: W/m² × panel area(~2m²) × efficiency
      final estimatedW = wm2 * 2.0 * AppConfig.systemEfficiency;
      return WeatherForecast(DateTime.parse(times[i]), wm2, estimatedW);
    });
  }
}
