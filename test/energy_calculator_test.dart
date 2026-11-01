import 'package:flutter_test/flutter_test.dart';
import 'package:equicare_energy/services/energy_calculator.dart';

void main() {
  test('runtime calculation', () {
    final h = EnergyCalculator.estimateRuntimeHours(
      batteryPercent: 50, batteryCapacityWh: 2400, currentLoadW: 600,
    );
    expect(h, closeTo(2.0, 0.01));
  });

  test('charge time is infinity with negative net', () {
    final h = EnergyCalculator.estimateChargeHours(
      batteryPercent: 40, targetPercent: 100, batteryCapacityWh: 2400,
      solarInputW: 100, currentLoadW: 200,
    );
    expect(h, double.infinity);
  });

  test('reserve and efficiency reduce available autonomy', () {
    final h = EnergyCalculator.estimateRuntimeHours(
      batteryPercent: 80, batteryCapacityWh: 2000, currentLoadW: 400,
      reservePercent: 10, efficiency: 0.8,
    );
    expect(h, closeTo(2.8, 0.001));
  });

  test('autonomy compares approved flexible load scenario', () {
    final result = EnergyCalculator.estimateAutonomy(
      batteryPercent: 80, batteryCapacityWh: 2000, currentLoadW: 500,
      flexibleLoadReductionW: 200, reservePercent: 10, efficiency: 1,
    );
    expect(result.currentHours, closeTo(2.8, 0.001));
    expect(result.reducedLoadHours, closeTo(4.6667, 0.001));
    expect(result.extensionHours, closeTo(1.8667, 0.001));
  });

  test('Jain fairness index is one for equal ratios', () {
    expect(EnergyCalculator.jainsFairnessIndex([1, 1, 1, 1]), closeTo(1, 0.0001));
  });

  test('Jain fairness index penalizes unequal ratios', () {
    expect(EnergyCalculator.jainsFairnessIndex([1, 1, 1, 4]), lessThan(1));
  });

  test('zero load means runtime is not load-limited', () {
    expect(EnergyCalculator.estimateRuntimeHours(
      batteryPercent: 80, batteryCapacityWh: 2000, currentLoadW: 0,
    ), double.infinity);
  });
}
