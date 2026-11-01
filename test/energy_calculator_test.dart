import 'package:flutter_test/flutter_test.dart';
import 'package:equicare_energy/services/energy_calculator.dart';

void main() {
  test('runtime calculation', () {
    final h = EnergyCalculator.estimateRuntimeHours(
      batteryPercent: 50,
      batteryCapacityWh: 2400,
      currentLoadW: 600,
    );
    expect(h, closeTo(2.0, 0.01));
  });

  test('charge time is infinity with negative net', () {
    final h = EnergyCalculator.estimateChargeHours(
      batteryPercent: 40,
      targetPercent: 100,
      batteryCapacityWh: 2400,
      solarInputW: 100,
      currentLoadW: 200,
    );
    expect(h, double.infinity);
  });
}
