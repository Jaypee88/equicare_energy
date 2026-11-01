import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/models.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static DateTime? _lastAlertTime;

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(settings);
  }

  static Future<void> showAlert(Alert alert) async {
    if (alert.severity != Severity.critical) return;

    if (_lastAlertTime != null &&
        DateTime.now().difference(_lastAlertTime!).inMinutes < 10) {
      return;
    }

    _lastAlertTime = DateTime.now();

    const androidDetails = AndroidNotificationDetails(
      'equicare_alerts',
      'System Alerts',
      channelDescription: 'Critical battery and energy alerts',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      alert.at.millisecondsSinceEpoch ~/ 1000,
      alert.title,
      alert.message,
      details,
    );
  }
}
