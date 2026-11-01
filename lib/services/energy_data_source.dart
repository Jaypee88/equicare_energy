class EnergyReading {
  final DateTime time;
  final double batteryPercent;
  final double loadW;
  final double solarW;
  EnergyReading(this.time, this.batteryPercent, this.loadW, this.solarW);
}

/// Contract every data source must fulfil. The app never cares whether
/// readings come from a simulator, an ESP32, or a cloud API — only that
/// they keep arriving on this stream.
abstract class EnergyDataSource {
  Stream<EnergyReading> readings();
  Future<void> close();
}
