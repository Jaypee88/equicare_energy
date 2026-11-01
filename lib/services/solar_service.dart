import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/models.dart';

class SolarService {
  static const _base = 'https://api.open-meteo.com/v1/forecast';

  Future<List<WeatherForecast>> fetchForecast({
    required double lat,
    required double lon,
    required double panelCapacityWp,
  }) async {
    final uri = Uri.parse(_base).replace(queryParameters: {
      'latitude': '$lat',
      'longitude': '$lon',
      'hourly': 'shortwave_radiation',
      'forecast_days': '2',
      'timezone': 'auto',
    });
    final res = await http.get(uri).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) throw Exception('Weather fetch failed: ${res.statusCode}');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final hourly = data['hourly'] as Map<String, dynamic>;
    final times = List<String>.from(hourly['time'] as List);
    final radiation = List<dynamic>.from(hourly['shortwave_radiation'] as List);
    return List.generate(times.length, (i) {
      final wm2 = radiation[i] == null ? 0.0 : (radiation[i] as num).toDouble();
      // Approximate panel output using rated panel capacity and irradiance.
      // This is a planning estimate, not measured PV output.
      final estimatedW = (wm2 / 1000 * panelCapacityWp * AppConfig.systemEfficiency)
          .clamp(0.0, panelCapacityWp).toDouble();
      return WeatherForecast(DateTime.parse(times[i]), wm2, estimatedW);
    });
  }
}
