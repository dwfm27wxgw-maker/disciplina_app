import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _inited = false;

  // SharedPrefs key para mostrar en UI la próxima programación
  static const String _kNextCoachAt = 'next_coach_at_v1';

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'disciplina_coach_monthly',
    'Coach mensual',
    description: 'Recordatorios mensuales del Coach Disciplina',
    importance: Importance.high,
  );

  static Future<void> init() async {
    if (_inited) return;

    try {
      tzdata.initializeTimeZones();

      // flutter_timezone puede devolver String o TimezoneInfo según versión
      try {
        final dynamic tzResult = await FlutterTimezone.getLocalTimezone();
        final String name = (tzResult is String)
            ? tzResult
            : (tzResult?.name?.toString() ?? 'Europe/Madrid');
        tz.setLocalLocation(tz.getLocation(name));
      } catch (_) {
        // fallback: tz.local
      }

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      final iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      final initSettings =
          InitializationSettings(android: androidInit, iOS: iosInit);

      await _initializeCompat(initSettings);

      if (!kIsWeb && Platform.isAndroid) {
        final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.createNotificationChannel(_androidChannel);
      }

      _inited = true;
    } catch (e) {
      debugPrint('NotificationService.init error: $e');
    }
  }

  // --------------------
  // UI helpers (persist)
  // --------------------

  static Future<DateTime?> getNextScheduledCoachAt() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final iso = sp.getString(_kNextCoachAt);
      if (iso == null || iso.trim().isEmpty) return null;
      return DateTime.tryParse(iso);
    } catch (_) {
      return null;
    }
  }

  static Future<void> _saveNextScheduledCoachAt(DateTime dt) async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_kNextCoachAt, dt.toIso8601String());
    } catch (_) {}
  }

  static tz.TZDateTime _nextMonthFirstDayAtLocal({
    required int hour,
    required int minute,
  }) {
    final now = tz.TZDateTime.now(tz.local);
    final nextYear = (now.month == 12) ? now.year + 1 : now.year;
    final nextMonth = (now.month == 12) ? 1 : now.month + 1;

    var scheduled =
        tz.TZDateTime(tz.local, nextYear, nextMonth, 1, hour, minute);

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static Future<DateTime?> scheduleNextMonthCoachAndReturnDate({
    int hour = 9,
    int minute = 0,
  }) async {
    await scheduleNextMonthCoach(hour: hour, minute: minute);
    return getNextScheduledCoachAt();
  }

  static Future<void> rescheduleNextMonthCoach({
    int hour = 9,
    int minute = 0,
  }) async {
    await scheduleNextMonthCoach(hour: hour, minute: minute);
  }

  // --------------------
  // Actions
  // --------------------

  static Future<void> showMonthlyCoachNow({
    String title = 'Coach mensual',
    String body = 'Disciplina: notificación de prueba.',
  }) async {
    try {
      await init();

      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      );

      await _showCompat(
        id: 9001,
        title: title,
        body: body,
        details: details,
      );
    } catch (e) {
      debugPrint('showMonthlyCoachNow error: $e');
    }
  }

  static Future<void> scheduleNextMonthCoach({
    int hour = 9,
    int minute = 0,
    String title = 'Coach mensual',
    String body = 'Disciplina: abre la app para ver tu recomendación del mes.',
  }) async {
    try {
      await init();

      final when = _nextMonthFirstDayAtLocal(hour: hour, minute: minute);

      await _saveNextScheduledCoachAt(DateTime(
        when.year,
        when.month,
        when.day,
        when.hour,
        when.minute,
      ));

      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      );

      await _cancelCompat(9002);

      await _zonedScheduleCompat(
        id: 9002,
        title: title,
        body: body,
        when: when,
        details: details,
      );
    } catch (e) {
      debugPrint('scheduleNextMonthCoach error: $e');
    }
  }

  // --------------------
  // Compat layer (API drift safe)
  // --------------------

  static Future<void> _initializeCompat(InitializationSettings settings) async {
    // ✅ Firma nueva (la tuya): initialize(settings: ...)
    try {
      await Function.apply(
        _plugin.initialize,
        const [],
        <Symbol, dynamic>{#settings: settings},
      );
      return;
    } catch (_) {}

    // Firma anterior: initialize(initializationSettings: ...)
    try {
      await Function.apply(
        _plugin.initialize,
        const [],
        <Symbol, dynamic>{#initializationSettings: settings},
      );
      return;
    } catch (_) {}

    // Firma vieja: initialize(settings posicional)
    try {
      await Function.apply(_plugin.initialize, [settings]);
      return;
    } catch (e) {
      debugPrint('initializeCompat failed: $e');
    }
  }

  static Future<void> _cancelCompat(int id) async {
    // Intento 1: cancel(id: id)
    try {
      await Function.apply(
        _plugin.cancel,
        const [],
        <Symbol, dynamic>{#id: id},
      );
      return;
    } catch (_) {}

    // Intento 2: cancel(id)
    try {
      await Function.apply(_plugin.cancel, [id]);
      return;
    } catch (e) {
      debugPrint('cancelCompat failed: $e');
    }
  }

  static Future<void> _showCompat({
    required int id,
    required String title,
    required String body,
    required NotificationDetails details,
  }) async {
    // Intento 1: show(id:..., title:..., body:..., notificationDetails:...)
    try {
      await Function.apply(
        _plugin.show,
        const [],
        <Symbol, dynamic>{
          #id: id,
          #title: title,
          #body: body,
          #notificationDetails: details,
        },
      );
      return;
    } catch (_) {}

    // Intento 2: show(id, title, body, details)
    try {
      await Function.apply(_plugin.show, [id, title, body, details]);
      return;
    } catch (e) {
      debugPrint('showCompat failed: $e');
    }
  }

  static Future<void> _zonedScheduleCompat({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
    required NotificationDetails details,
  }) async {
    // Intento 1 (firma nueva): zonedSchedule(id:..., scheduledDate:..., notificationDetails:..., androidScheduleMode:...)
    try {
      await Function.apply(
        _plugin.zonedSchedule,
        const [],
        <Symbol, dynamic>{
          #id: id,
          #title: title,
          #body: body,
          #scheduledDate: when,
          #notificationDetails: details,
          #androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        },
      );
      return;
    } catch (_) {}

    // Intento 2 (firma vieja): zonedSchedule(id, title, body, when, details, androidAllowWhileIdle: true)
    try {
      await Function.apply(
        _plugin.zonedSchedule,
        [id, title, body, when, details],
        <Symbol, dynamic>{#androidAllowWhileIdle: true},
      );
      return;
    } catch (e) {
      debugPrint('zonedScheduleCompat failed: $e');
    }
  }
}