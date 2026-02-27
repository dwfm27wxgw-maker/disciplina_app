import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _inited = false;

  static const int _monthlyCoachId = 1001;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'disciplina_monthly_coach',
    'Disciplina - Coach mensual',
    description: 'Aviso mensual con recomendación de inversión',
    importance: Importance.high,
  );

  static Future<void> init() async {
    await _ensureInit();
  }

  static Future<void> rescheduleNextMonthCoach() async {
    await _ensureInit();
    // MVP: scheduling real lo hacemos después con timezone
  }

  static Future<bool> _ensureInit() async {
    if (_inited) return true;
    _inited = true;

    if (kIsWeb) return false;
    if (!(Platform.isAndroid || Platform.isIOS)) return false;

    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();

      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );

      // ✅ API nueva: settings: ...
      await _plugin.initialize(settings: initSettings);

      if (Platform.isAndroid) {
        final androidImpl = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

        try {
          await androidImpl?.createNotificationChannel(_channel);
        } catch (_) {}

        try {
          await androidImpl?.requestNotificationsPermission();
        } catch (_) {}
      }

      return true;
    } catch (e) {
      debugPrint('NotificationService init error: $e');
      return false;
    }
  }

  static NotificationDetails _details() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }

  static Future<void> showMonthlyCoachNow({
    String title = 'Disciplina',
    String body = 'Coach mensual listo.',
  }) async {
    final ok = await _ensureInit();
    if (!ok) return;

    // ✅ API nueva: id/title/body/notificationDetails nombrados
    await _plugin.show(
      id: _monthlyCoachId,
      title: title,
      body: body,
      notificationDetails: _details(),
    );
  }

  static Future<void> scheduleNextMonthCoach({
    String title = 'Disciplina',
    String body = 'Tu recomendación mensual está lista.',
  }) async {
    final ok = await _ensureInit();
    if (!ok) return;

    // MVP: sin programación exacta todavía (lo hacemos luego con timezone bien)
  }

  static Future<void> cancelMonthlyCoach() async {
    final ok = await _ensureInit();
    if (!ok) return;

    // ✅ API nueva: cancel(id: ...)
    await _plugin.cancel(id: _monthlyCoachId);
  }
}