class AppConfig {
  static const double defaultBatteryCapacityWh = 2400; // ~200Ah @ 12V
  static const double defaultPanelCapacityWp = 400;
  static const double systemEfficiency = 0.75;

  static const double lowBatteryPercent = 30;
  static const double criticalBatteryPercent = 15;
  static const double highLoadFactor = 1.5;
}
