import 'package:flutter/foundation.dart';

/// AppBus: notificaciones internas de la app (sin dependencias).
/// Usamos un contador que sube cada vez que cambia algo importante.
class AppBus {
  AppBus._();

  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  /// Llama a esto cuando guardes movimientos/plan/tickers, etc.
  static void bump() {
    changes.value = changes.value + 1;
  }
}
