import 'package:flutter/foundation.dart';

import '../../../core/models/movement.dart';
import '../../../core/models/plan.dart';
import '../../../core/storage/local_store.dart';

@immutable
class MonthlyDigest {
  final String title;
  final String message;
  final bool monthCompleted;
  final DateTime generatedAt;

  // Compatibilidad con MonthlyDigestScreen (campos antiguos)
  String get headline => title;
  String get actionLine => message;
  String get fullBody => message;


  const MonthlyDigest({
    required this.title,
    required this.message,
    required this.monthCompleted,
    required this.generatedAt,
  });
}

class MonthlyDigestService {
  static Future<MonthlyDigest> buildDigest({
    Plan? plan,
    DateTime? now,
  }) async {
    final DateTime t = now ?? DateTime.now();
    final List<dynamic> raw = await LocalStore.getMovements();

    final List<Movement> moves = raw
        .map((e) {
          if (e is Movement) return e;
          if (e is Map<String, dynamic>) return Movement.fromJson(e);
          if (e is Map) return Movement.fromJson(Map<String, dynamic>.from(e));
          return null;
        })
        .whereType<Movement>()
        .toList();

    final List<Movement> monthMoves = moves.where((m) {
      final d = m.date;
      return d.year == t.year && d.month == t.month;
    }).toList();

    final double investedThisMonth =
        monthMoves.fold(0.0, (sum, m) => sum + (m.amount));

    final double targetMonthly = plan?.monthlyContribution ?? 50.0;
    final double remaining = (targetMonthly - investedThisMonth);
    final bool completed = remaining <= 0.01;

    final String monthName = _monthNameEs(t.month);

    if (completed) {
      return MonthlyDigest(
        title: "Mes completado · $monthName",
        message:
            "Bien. Este mes ya has cubierto tu objetivo (≈ ${investedThisMonth.toStringAsFixed(0)} €). "
            "No toques nada. El siguiente paso es repetir el mes que viene.",
        monthCompleted: true,
        generatedAt: t,
      );
    }    String suggestion;
    if (plan != null && plan.targetWeights.isNotEmpty) {
      final entries = plan.targetWeights.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final top = entries.take(3).toList();

      final parts = top.map((e) {
        final eur = (remaining * e.value).clamp(0, remaining);
        return "${e.key}: ${eur.toStringAsFixed(0)}€";
      }).join(" · ");

      suggestion =
          "Te quedan ${remaining.toStringAsFixed(0)}€ para cerrar $monthName. "
          "Reparte así: $parts.";
    } else {
      suggestion =
          "Te quedan ${remaining.toStringAsFixed(0)}€ para cerrar $monthName. "
          "MVP: compra MSCI World (o tu ETF principal) y ya está.";
    }

    return MonthlyDigest(
      title: "Coach mensual · $monthName",
      message: suggestion,
      monthCompleted: false,
      generatedAt: t,
    );
  }

  static Future<MonthlyDigest> buildDigestForNow({bool? monthDone}) {
    return buildDigest();
  }  static String _monthNameEs(int m) {
    const months = [
      "enero", "febrero", "marzo", "abril", "mayo", "junio",
      "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"
    ];
    return months[(m - 1).clamp(0, 11)];
  }
}
