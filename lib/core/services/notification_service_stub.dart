// lib/core/services/notification_service_stub.dart
// ✅ Implementación vacía para Windows/Web/otras plataformas.
// No importa flutter_local_notifications, así que no rompe el build.

class NotificationService {
  static Future<void> init() async {}

  static Future<void> rescheduleNextMonthCoach() async {}

  static Future<void> showMonthlyCoachNow({
    String title = 'Disciplina',
    String body = 'Coach mensual listo.',
  }) async {}

  static Future<void> scheduleNextMonthCoach({
    String title = 'Disciplina',
    String body = 'Tu recomendación mensual está lista.',
  }) async {}

  static Future<void> cancelMonthlyCoach() async {}
}
