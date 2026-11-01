import 'package:flutter/material.dart';

class BatteryGauge extends StatelessWidget {
  final double percent;
  const BatteryGauge({super.key, required this.percent});

  Color get _color {
    if (percent < 15) return Colors.red;
    if (percent < 30) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: (percent / 100).clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, animatedValue, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: CircularProgressIndicator(
                  value: animatedValue,
                  strokeWidth: 18,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(_color),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${percent.round()}%',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text('battery', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
