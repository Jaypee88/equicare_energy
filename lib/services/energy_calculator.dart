class AutonomyEstimate {
  final double currentHours;
  final double reducedLoadHours;
  final double extensionHours;
  const AutonomyEstimate({required this.currentHours, required this.reducedLoadHours, required this.extensionHours});
}

class EnergyCalculator {
  static double estimateRuntimeHours({
    required double batteryPercent,
    required double batteryCapacityWh,
    required double currentLoadW,
    double reservePercent = 0,
    double efficiency = 1,
  }) {
    if (batteryCapacityWh <= 0 || batteryPercent <= reservePercent || efficiency <= 0) return 0;
    if (currentLoadW <= 0) return double.infinity;
    final usableWh = batteryCapacityWh * ((batteryPercent - reservePercent) / 100) * efficiency;
    return usableWh / currentLoadW;
  }

  static AutonomyEstimate estimateAutonomy({
    required double batteryPercent,
    required double batteryCapacityWh,
    required double currentLoadW,
    required double flexibleLoadReductionW,
    double reservePercent = 10,
    double efficiency = 0.85,
  }) {
    if (flexibleLoadReductionW < 0 || currentLoadW < 0) throw ArgumentError('Loads cannot be negative.');
    final reducedLoad = (currentLoadW - flexibleLoadReductionW).clamp(0.0, currentLoadW).toDouble();
    final before = estimateRuntimeHours(batteryPercent: batteryPercent, batteryCapacityWh: batteryCapacityWh, currentLoadW: currentLoadW, reservePercent: reservePercent, efficiency: efficiency);
    final after = estimateRuntimeHours(batteryPercent: batteryPercent, batteryCapacityWh: batteryCapacityWh, currentLoadW: reducedLoad, reservePercent: reservePercent, efficiency: efficiency);
    final extension = after.isFinite ? (after - before).clamp(0.0, double.infinity) : 0.0;
    return AutonomyEstimate(currentHours: before, reducedLoadHours: after, extensionHours: extension);
  }

  static double jainsFairnessIndex(List<double> values) {
    if (values.isEmpty || values.any((v) => v < 0)) return 0;
    final sum = values.fold<double>(0, (a, b) => a + b);
    final squares = values.fold<double>(0, (a, b) => a + b * b);
    if (squares == 0) return 1;
    return (sum * sum) / (values.length * squares);
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
    final neededWh = batteryCapacityWh * ((targetPercent - batteryPercent) / 100);
    if (neededWh <= 0) return 0;
    return neededWh / netW;
  }
}
