import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'energy_data_source.dart';

/// Talks to an ESP32 (or any device) that serves:
///   GET {baseUrl}/api/status
///   {
///     "batteryPercent": 67.4,
///     "loadW": 320.5,
///     "solarW": 415.2,
///     "time": "2026-10-28T14:32:00Z"   // optional, falls back to now()
///   }
class HttpEnergyDataSource implements EnergyDataSource {
  HttpEnergyDataSource({
    required this.baseUrl,
    this.pollPeriod = const Duration(seconds: 5),
  });

  /// e.g. 'http://equicare.local' or 'http://192.168.1.42'
  final String baseUrl;
  final Duration pollPeriod;

  final _controller = StreamController<EnergyReading>.broadcast();
  Timer? _timer;
  bool _inFlight = false;

  @override
  Stream<EnergyReading> readings() {
    _timer ??= Timer.periodic(pollPeriod, (_) => _poll());
    return _controller.stream;
  }

  Future<void> _poll() async {
    if (_inFlight) return;
    _inFlight = true;
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/api/status'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final m = jsonDecode(res.body) as Map<String, dynamic>;
        final reading = EnergyReading(
          DateTime.tryParse(m['time'] as String? ?? '') ?? DateTime.now(),
          (m['batteryPercent'] as num).toDouble(),
          (m['loadW'] as num).toDouble(),
          (m['solarW'] as num).toDouble(),
        );
        _controller.add(reading);
      }
    } catch (_) {
      // Swallow — provider's offline badge already handles UX for this.
    } finally {
      _inFlight = false;
    }
  }

  @override
  Future<void> close() async {
    _timer?.cancel();
    await _controller.close();
  }
}
