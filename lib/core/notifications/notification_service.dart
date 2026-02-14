import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../coach/monthly_digest_service.dart';
import '../storage/local_store.dart';
import '../storage/local_store_monthly.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _monthlyCoachId = 1001;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'disciplina_monthly_coach',
    'Disciplina - Coach mensual',
    description: 'Aviso mensual con recomendación de inversión',
    importance: Importance.high,
  );

  static Future<void> init() async {
    try {
      tzdata.initializeTimeZones();
      final localTzName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTzName));
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('⚠️ timezone init failed: $e');
      }
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const init = InitializationSettings(android: androidInit);

    await _plugin.initialize(init);

    // Android channel
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(_channel);
    } catch (_) {}

    // iOS permissions (si lo ejecutas en iOS, pide permisos)
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (_) {}
  }

  static tz.TZDateTime _nextMonthAt10() {
    final now = tz.TZDateTime.now(tz.local);
    final nextMonth = (now.month == 12) ? 1 : now.month + 1;
    final year = (now.month == 12) ? now.year + 1 : now.year;

    // día 1 del mes siguiente a las 10:00
    return tz.TZDateTime(tz.local, year, nextMonth, 1, 10, 0);
  }

  static String _monthNameEs(int m) {
    const names = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    if (m < 1 || m > 12) return 'Mes';
    return names[m - 1];
  }

  static Future<void> rescheduleNextMonthCoach() async {
    try {
      final next = _nextMonthAt10();

      // En la notificación no metemos números “vivos” (porque cambian),
      // pero sí un resumen útil + llamada a abrir la app.
      final plan = await LocalStore.getPlan();
      final weights = plan?.targetWeights ?? {};
      final monthly = plan?.monthlyContribution ?? 50.0;

      final monthName = _monthNameEs(next.month);
      final title = 'Disciplina • $monthName ${next.year}';
      final body = weights.isEmpty
          ? 'Define tu Plan para recibir recomendaciones mensuales.'
          : 'Objetivo: ${monthly.toStringAsFixed(0)}€ este mes. Abre Disciplina para ver tu reparto recomendado.';

      final completed =
          await LocalStoreMonthly.isMonthCompleted(next.year, next.month);

      // Si el usuario lo marcó completado por alguna razón, no programamos.
      if (completed) {
        return;
      }

      await _plugin.zonedSchedule(
        _monthlyCoachId,
        title,
        body,
        next,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      );

      if (kDebugMode) {
        // ignore: avoid_print
        print('✅ Monthly coach scheduled for: $next');
      }
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('⚠️ rescheduleNextMonthCoach failed: $e');
      }
    }
  }

  /// Botón de prueba: lanza ahora una notificación con el estado real del mes actual.
  static Future<void> testCoachNow() async {
    try {
      final now = DateTime.now();
      final plan = await LocalStore.getPlan();
      final movements = await LocalStore.getMovements();

      final digest = MonthlyDigestService.generate(
        year: now.year,
        month: now.month,
        plan: plan,
        movements: movements,
      );

      final monthName = _monthNameEs(now.month);
      final title = 'Disciplina • $monthName ${now.year}';

      String body;
      if (plan == null || (plan.targetWeights.isEmpty)) {
        body = 'Crea tu Plan para recibir recomendaciones.';
      } else if (digest.remainingEur <= 0.0001) {
        body = 'Mes completado ✅. Buen trabajo.';
      } else if (digest.suggestions.isEmpty) {
        body =
            'Te quedan ${digest.remainingEur.toStringAsFixed(0)}€. Mantén tu plan.';
      } else {
        final top = digest.suggestions.take(2).toList();
        final parts = top
            .map((s) => '${s.ticker} ${s.amountEur.toStringAsFixed(0)}€')
            .join(' · ');
        body =
            'Te quedan ${digest.remainingEur.toStringAsFixed(0)}€. Prioriza: $parts.';
      }

      await _plugin.show(
        2002,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'disciplina_test',
            'Disciplina - Test',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('⚠️ testCoachNow failed: $e');
      }
    }
  }
}
