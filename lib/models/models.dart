enum Severity { info, warning, critical }

class Alert {
  final Severity severity;
  final String title;
  final String message;
  final DateTime at;
  Alert(this.severity, this.title, this.message, [DateTime? at])
      : at = at ?? DateTime.now();
}

class ConsumptionRecord {
  final DateTime time;
  final double loadW;
  final double batteryPercent;
  final String source;
  ConsumptionRecord(this.time, this.loadW, this.batteryPercent, {this.source = 'unknown'});

  Map<String, dynamic> toMap() => {
    't': time.millisecondsSinceEpoch, 'l': loadW, 'b': batteryPercent, 's': source,
  };
  factory ConsumptionRecord.fromMap(Map m) => ConsumptionRecord(
    DateTime.fromMillisecondsSinceEpoch(m['t'] as int),
    (m['l'] as num).toDouble(),
    (m['b'] as num).toDouble(),
    source: m['s'] as String? ?? 'unknown',
  );
}

class WeatherForecast {
  final DateTime time;
  final double irradianceWm2;
  final double estimatedSolarW;
  WeatherForecast(this.time, this.irradianceWm2, this.estimatedSolarW);

  Map<String, dynamic> toMap() => {
    'time': time.toIso8601String(),
    'irradianceWm2': irradianceWm2,
    'estimatedSolarW': estimatedSolarW,
  };
  factory WeatherForecast.fromMap(Map<String, dynamic> map) => WeatherForecast(
    DateTime.parse(map['time'] as String),
    (map['irradianceWm2'] as num).toDouble(),
    (map['estimatedSolarW'] as num).toDouble(),
  );
}
