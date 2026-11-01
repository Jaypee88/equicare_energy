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
  ConsumptionRecord(this.time, this.loadW, this.batteryPercent);

  Map<String, dynamic> toMap() => {
    't': time.millisecondsSinceEpoch,
    'l': loadW,
    'b': batteryPercent,
  };
  factory ConsumptionRecord.fromMap(Map m) => ConsumptionRecord(
    DateTime.fromMillisecondsSinceEpoch(m['t']),
    (m['l'] as num).toDouble(),
    (m['b'] as num).toDouble(),
  );
}

class WeatherForecast {
  final DateTime time;
  final double irradianceWm2;
  final double estimatedSolarW;
  WeatherForecast(this.time, this.irradianceWm2, this.estimatedSolarW);
}
