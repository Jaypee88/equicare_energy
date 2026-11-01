import 'package:flutter/material.dart';
import '../models/models.dart';

class AlertTile extends StatelessWidget {
  final Alert alert;
  const AlertTile({super.key, required this.alert});

  Color get _color => switch (alert.severity) {
    Severity.info => Colors.blue,
    Severity.warning => Colors.orange,
    Severity.critical => Colors.red,
  };

  IconData get _icon => switch (alert.severity) {
    Severity.info => Icons.info_outline,
    Severity.warning => Icons.warning_amber,
    Severity.critical => Icons.error_outline,
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _color.withOpacity(0.08),
      child: ListTile(
        leading: Icon(_icon, color: _color),
        title: Text(
          alert.title,
          style: TextStyle(color: _color, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(alert.message),
      ),
    );
  }
}
