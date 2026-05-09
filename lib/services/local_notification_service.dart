import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class GrowlitLocalNotificationService {
  GrowlitLocalNotificationService._();

  static final GrowlitLocalNotificationService instance =
      GrowlitLocalNotificationService._();

  static const String _channelId = 'growlit_device_alerts';
  static const String _channelName = 'GrowLit Alerts';
  static const String _channelDescription = 'Notifications for lamp and pump events';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _plugin.initialize(settings: initializationSettings);

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.max,
        ),
      );
      await androidPlugin.requestNotificationsPermission();
    }
  }

  Future<void> showAlert({
    required String title,
    required String body,
    required String payload,
  }) async {
    final details = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    final notificationDetails = NotificationDetails(android: details);
    final id = DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);

    if (kDebugMode) {
      debugPrint('Showing system notification: $title - $body');
    }

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payload,
    );
  }
}