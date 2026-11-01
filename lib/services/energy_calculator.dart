class EnergyCalculator {
  static double estimateRuntimeHours({
    required double batteryPercent,
    required double batteryCapacityWh,
    required double currentLoadW,
  }) {
    if (currentLoadW <= 0) return double.infinity;
    final remainingWh = batteryCapacityWh * (batteryPercent / 100);
    return remainingWh / currentLoadW;
  }

  static double estimateChargeHours({
    required double batteryPercent,
    required double targetPercent,
    required double batteryCapacityWh,
    required double solarInputW,
    required double currentLoadW,
  }) {
    final netW = solarInputW - currentLoadW;
    if (netW <= 0) return double.infinity;
    final neededWh =
        batteryCapacityWh * ((targetPercent - batteryPercent) / 100);
    if (neededWh <= 0) return 0;
    return neededWh / netW;
  }
}
