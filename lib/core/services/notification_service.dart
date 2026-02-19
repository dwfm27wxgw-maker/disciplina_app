import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Notificaciones Disciplina (Android-first)
/// Compatible con flutter_local_notifications (API nueva con named params)
/// y flutter_timezone 5.0.1 (getLocalTimezone devuelve TimezoneInfo en tu caso).
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _monthlyCoachId = 1001;
  static const int _testId = 1002;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'disciplina_monthly_coach',
    'Disciplina - Coach mensual',
    description: 'Aviso mensual con recomendación de inversión',
    importance: Importance.high,
  );

  static Future<void> init() async {
    // ✅ Timezone
    tzdata.initializeTimeZones();

    final tzName = await _safeGetLocalTimezoneName();
    try {
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (_) {
      // fallback
      tz.setLocalLocation(tz.getLocation('Europe/Madrid'));
    }

    // ✅ Init Android
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse r) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('Notification tapped. payload=${r.payload}');
        }
      },
    );

    // ✅ Canal Android
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(_channel);

    // ✅ Android 13+ permiso (si existe en tu versión)
    try {
      await android?.requestNotificationsPermission();
    } catch (_) {}
  }

  /// ✅ Existe para tu HomePage
  static Future<void> showMonthlyCoachNow({
    String title = 'Disciplina — Coach mensual',
    String body =
        'Revisión mensual lista. Abre Disciplina para ver qué comprar este mes.',
  }) async {
    await _plugin.show(
      id: _monthlyCoachId,
      title: title,
      body: body,
      notificationDetails: _details(),
      payload: 'monthly_coach_now',
    );
  }

  /// Notificación de prueba inmediata
  static Future<void> showTestNow() async {
    await _plugin.show(
      id: _testId,
      title: 'Disciplina — Prueba',
      body: 'Si ves esto, las notificaciones funcionan ✅',
      notificationDetails: _details(),
      payload: 'test_now',
    );
  }

  /// Programa el próximo aviso mensual (día/hora)
  static Future<void> scheduleNextMonthCoach({
    int day = 1,
    int hour = 9,
    int minute = 30,
  }) async {
    await _plugin.cancel(id: _monthlyCoachId);

    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime next = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      day,
      hour,
      minute,
    );

    if (!next.isAfter(now)) {
      final monthPlus1 = tz.TZDateTime(tz.local, now.year, now.month + 1, 1);
      next = tz.TZDateTime(
        tz.local,
        monthPlus1.year,
        monthPlus1.month,
        day,
        hour,
        minute,
      );
    }

    await _plugin.zonedSchedule(
      id: _monthlyCoachId,
      title: 'Disciplina — Coach mensual',
      body: 'Toca para ver qué comprar este mes.',
      scheduledDate: next,
      notificationDetails: _details(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'monthly_coach_scheduled',
    );
  }

  /// ✅ Alias para que compile tu código actual (lo llamas desde 2 pantallas)
  static Future<void> rescheduleNextMonthCoach() async {
    await scheduleNextMonthCoach();
  }

  static Future<void> cancelMonthlyCoach() async {
    await _plugin.cancel(id: _monthlyCoachId);
  }

  static NotificationDetails _details() {
    const android = AndroidNotificationDetails(
      'disciplina_monthly_coach',
      'Disciplina - Coach mensual',
      channelDescription: 'Aviso mensual con recomendación de inversión',
      importance: Importance.high,
      priority: Priority.high,
    );
    return const NotificationDetails(android: android);
  }

  static Future<String> _safeGetLocalTimezoneName() async {
    // flutter_timezone 5.0.1 en tu caso devuelve TimezoneInfo (no String)
    // así que lo tratamos como dynamic y extraemos un nombre válido.
    try {
      final dynamic v = await FlutterTimezone.getLocalTimezone();
      final extracted = _extractTimezoneName(v);
      return extracted.isNotEmpty ? extracted : 'Europe/Madrid';
    } catch (_) {
      return 'Europe/Madrid';
    }
  }

  static String _extractTimezoneName(dynamic v) {
    if (v == null) return 'Europe/Madrid';

    // Caso String
    if (v is String) {
      final s = v.trim();
      if (s.isNotEmpty) return s;
    }

    // Caso TimezoneInfo o cualquier objeto: intentamos propiedades típicas con dynamic
    try {
      final dynamic tz1 = (v as dynamic).timezone;
      if (tz1 is String && tz1.trim().isNotEmpty) return tz1.trim();
    } catch (_) {}
    try {
      final dynamic tz2 = (v as dynamic).timeZone;
      if (tz2 is String && tz2.trim().isNotEmpty) return tz2.trim();
    } catch (_) {}
    try {
      final dynamic tz3 = (v as dynamic).id;
      if (tz3 is String && tz3.trim().isNotEmpty) return tz3.trim();
    } catch (_) {}
    try {
      final dynamic tz4 = (v as dynamic).identifier;
      if (tz4 is String && tz4.trim().isNotEmpty) return tz4.trim();
    } catch (_) {}

    // Fallback: parsear el toString buscando algo tipo "Europe/Madrid"
    final s = v.toString();
    final m = RegExp(r'([A-Za-z_]+\/[A-Za-z_]+)').firstMatch(s);
    if (m != null && m.groupCount >= 1) {
      final found = m.group(1) ?? '';
      if (found.isNotEmpty) return found;
    }

    // Último fallback
    return 'Europe/Madrid';
  }
}
