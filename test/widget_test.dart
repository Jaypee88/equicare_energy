import 'package:equicare_energy/widgets/battery_gauge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('battery gauge displays the supplied state of charge', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: BatteryGauge(percent: 72))));
    expect(find.text('72%'), findsOneWidget);
    expect(find.text('battery'), findsOneWidget);
  });

  testWidgets('battery gauge clamps progress for values above 100 percent', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: BatteryGauge(percent: 120))));
    expect(find.text('120%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
