import '../../../core/models/movement.dart';
import '../../../core/models/plan.dart';
import '../../../core/storage/local_store.dart';

class MonthlyDigest {
  final String headline;
  final String actionLine;
  final String fullBody;

  const MonthlyDigest({
    required this.headline,
    required this.actionLine,
    required this.fullBody,
  });

  // compat con pantallas antiguas
  String get title => headline;
}

class MonthlyDigestService {
  static Future<MonthlyDigest> buildMonthlyDigest({DateTime? now}) async {
    final n = now ?? DateTime.now();
    final year = n.year;
    final month = n.month;

    final plan = await LocalStore.getPlan();
    final movements = await LocalStore.getMovements();
    final monthMovs = movements.where((m) => m.date.year == year && m.date.month == month).toList();

    final invested = monthMovs.fold<double>(0.0, (s, m) => s + m.amount);

    final monthlyTarget = plan?.monthlyContribution ?? 50.0;
    final remaining = (monthlyTarget - invested);
    final remainingSafe = remaining > 0 ? remaining : 0.0;

    // Pesos objetivo (si no hay plan: defaults)
    final weights = (plan?.targetWeights.isNotEmpty ?? false)
        ? plan!.targetWeights
        : <String, double>{'IWLE': 0.60, 'EUNU': 0.30, 'IS3N': 0.10};

    // Actual por ticker (según compras del mes)
    final byTicker = <String, double>{};
    for (final m in monthMovs) {
      byTicker[m.ticker] = (byTicker[m.ticker] ?? 0) + m.amount;
    }

    // Si ya está completado el mes, mensaje calmado
    if (remainingSafe <= 0.01) {
      return MonthlyDigest(
        headline: 'Mes completado ✅',
        actionLine: 'Este mes ya has invertido ${invested.toStringAsFixed(0)}€.',
        fullBody:
            'Perfecto. Ya has cumplido tu objetivo mensual (${monthlyTarget.toStringAsFixed(0)}€).\n'
            'Si quieres, revisa el Plan o simplemente mantén el rumbo.',
      );
    }

    // Recomendación: repartir el “remaining” según desviación vs objetivo
    // Objetivo de gasto por ticker este mes = monthlyTarget * weight
    // Si ya has gastado menos que eso, tiene prioridad.
    final priorities = <_TickerPriority>[];
    weights.forEach((ticker, w) {
      final targetEuro = monthlyTarget * w;
      final actualEuro = byTicker[ticker] ?? 0.0;
      final deficit = targetEuro - actualEuro; // positivo => falta
      priorities.add(_TickerPriority(ticker, w, targetEuro, actualEuro, deficit));
    });

    // Orden por mayor déficit relativo
    priorities.sort((a, b) => b.deficit.compareTo(a.deficit));

    // Asignación simple: top 3, proporcional a déficit positivo; si todos <=0, proporcional a weight
    final posSum = priorities.where((p) => p.deficit > 0).fold<double>(0.0, (s, p) => s + p.deficit);
    final alloc = <String, double>{};

    for (final p in priorities.take(3)) {
      final portion = (posSum > 0 && p.deficit > 0) ? (p.deficit / posSum) : p.weight;
      alloc[p.ticker] = remainingSafe * portion;
    }

    // normaliza por si weights no suman 1 en top3
    final allocSum = alloc.values.fold<double>(0.0, (s, v) => s + v);
    if (allocSum > 0) {
      alloc.updateAll((k, v) => (v / allocSum) * remainingSafe);
    }

    final top = alloc.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final first = top.isNotEmpty ? top.first : null;

    final headline = first == null
        ? 'Compra sugerida'
        : 'Prioridad: ${first.key}';

    final action = first == null
        ? 'Te quedan ${remainingSafe.toStringAsFixed(0)}€ este mes.'
        : 'Compra ~${first.value.toStringAsFixed(0)}€ en ${first.key}.';

    final lines = top.map((e) => '• ${e.key}: ${e.value.toStringAsFixed(0)}€').join('\n');

    return MonthlyDigest(
      headline: headline,
      actionLine: 'Te quedan ${remainingSafe.toStringAsFixed(0)}€ para completar el mes.',
      fullBody:
          'Objetivo mensual: ${monthlyTarget.toStringAsFixed(0)}€\n'
          'Invertido este mes: ${invested.toStringAsFixed(0)}€\n'
          'Restante: ${remainingSafe.toStringAsFixed(0)}€\n\n'
          'Reparto recomendado:\n$lines\n\n'
          'Nota: esto se basa en tu Plan (pesos objetivo) y tus compras del mes. No depende de precios en tiempo real.',
    );
  }
}

class _TickerPriority {
  final String ticker;
  final double weight;
  final double targetEuro;
  final double actualEuro;
  final double deficit;

  _TickerPriority(this.ticker, this.weight, this.targetEuro, this.actualEuro, this.deficit);
}