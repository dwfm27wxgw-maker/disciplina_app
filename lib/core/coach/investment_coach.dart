// ignore_for_file: unnecessary_type_check, unnecessary_null_comparison
import 'dart:math' as math;

import '../models/plan.dart';

class CoachSuggestion {
  final String ticker;
  final double suggestedEuro;
  final double behindEuro;
  final double targetEuro;
  final double currentEuro;
  final String reason;

  const CoachSuggestion({
    required this.ticker,
    required this.suggestedEuro,
    required this.behindEuro,
    required this.targetEuro,
    required this.currentEuro,
    required this.reason,
  });
}

class InvestmentCoach {
  static List<CoachSuggestion> buildMonthlySuggestions({
    required Plan plan,
    required List<dynamic> movements,
    DateTime? now,
    int topN = 3,
    double? budgetEuro,
    double minOrderEuro = 5.0,
    double roundToEuro = 5.0,
  }) {
    final double planBudget = _safeDouble(_getPlanMonthly(plan), fallback: 0.0);
    final double monthlyBudget = (budgetEuro != null)
        ? _safeDouble(budgetEuro, fallback: 0.0)
        : planBudget;

    if (monthlyBudget <= 0) return const [];

    final weightsRaw = _getPlanWeights(plan);
    final weights = _normalizedWeights(weightsRaw);
    if (weights.isEmpty) return const [];

    final byTicker = <String, double>{};
    for (final m in movements) {
      final t = _getMovementTicker(m);
      if (t.isEmpty) continue;
      if (t.toUpperCase() == 'UNKNOWN') continue;

      final amt = _getMovementAmount(m);
      if (amt <= 0) continue;

      byTicker[t] = (byTicker[t] ?? 0) + amt;
    }

    final double totalInvested = byTicker.values.fold(0.0, (a, b) => a + b);
    final double targetBase = totalInvested > 0 ? totalInvested : monthlyBudget;

    final behind = <String, double>{};
    final targetEuro = <String, double>{};
    final currentEuro = <String, double>{};

    for (final entry in weights.entries) {
      final ticker = entry.key;
      final w = entry.value;

      final cur = byTicker[ticker] ?? 0.0;
      final tgt = targetBase * w;

      currentEuro[ticker] = cur;
      targetEuro[ticker] = tgt;
      behind[ticker] = tgt - cur;
    }

    final laggards = behind.entries.where((e) => e.value > 0.01).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (laggards.isEmpty) return const [];

    final double sumBehind = laggards.fold(0.0, (a, e) => a + e.value);
    if (sumBehind <= 0) return const [];

    final allocations = <String, double>{};
    for (final e in laggards) {
      allocations[e.key] = monthlyBudget * (e.value / sumBehind);
    }

    final rounded = <String, double>{};
    for (final e in allocations.entries) {
      final v = _roundTo(e.value, roundToEuro);
      if (v >= minOrderEuro) rounded[e.key] = v;
    }

    if (rounded.isEmpty) {
      final top = laggards.first.key;
      rounded[top] = _roundTo(monthlyBudget, roundToEuro);
    }

    double sum = rounded.values.fold(0.0, (a, b) => a + b);
    if (sum > monthlyBudget) {
      final keysBySmall = rounded.keys.toList()
        ..sort((a, b) => (rounded[a] ?? 0).compareTo(rounded[b] ?? 0));
      var excess = sum - monthlyBudget;

      for (final k in keysBySmall) {
        if (excess <= 0.01) break;
        final v = rounded[k] ?? 0;
        final minAllowed = math.min(v, minOrderEuro);
        final reducible = v - minAllowed;
        final reduce = math.min(excess, reducible);
        if (reduce > 0) {
          rounded[k] = v - reduce;
          excess -= reduce;
        }
      }
    }

    final orderedTickers = rounded.keys.toList()
      ..sort((a, b) => (behind[b] ?? 0).compareTo(behind[a] ?? 0));

    final suggestions = <CoachSuggestion>[];
    for (final t in orderedTickers) {
      final sug = rounded[t] ?? 0;
      if (sug <= 0) continue;

      final b = behind[t] ?? 0;
      final tgt = targetEuro[t] ?? 0;
      final cur = currentEuro[t] ?? 0;

      suggestions.add(
        CoachSuggestion(
          ticker: t,
          suggestedEuro: sug,
          behindEuro: b,
          targetEuro: tgt,
          currentEuro: cur,
          reason: 'Vas por detrás en $t (+${b.toStringAsFixed(0)}€ aprox).',
        ),
      );
    }

    if (topN > 0 && suggestions.length > topN) {
      return suggestions.sublist(0, topN);
    }
    return suggestions;
  }

  // ----------------- helpers -----------------

  static Map<String, double> _normalizedWeights(Map<String, double> w) {
    final cleaned = <String, double>{};
    double sum = 0.0;

    for (final e in w.entries) {
      final k = e.key.trim().toUpperCase();
      final v = _safeDouble(e.value, fallback: 0.0);
      if (k.isEmpty || v <= 0) continue;
      cleaned[k] = v;
      sum += v;
    }
    if (sum <= 0) return {};
    return cleaned.map((k, v) => MapEntry(k, v / sum));
  }

  static double _roundTo(double value, double step) {
    if (step <= 0) return value;
    return (value / step).roundToDouble() * step;
  }

  static double _safeDouble(dynamic v, {double fallback = 0.0}) {
    if (v == null) return fallback;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    if (v is String) {
      final parsed = double.tryParse(v.replaceAll(',', '.'));
      return parsed ?? fallback;
    }
    return fallback;
  }

  static Map<String, double> _getPlanWeights(Plan plan) {
    try {
      final m = plan.targetWeights;
      if (m is Map<String, double>) return m;
      if (m is Map) {
        final out = <String, double>{};
        m.forEach((k, v) {
          if (k == null) return;
          out[k.toString()] = _safeDouble(v, fallback: 0.0);
        });
        return out;
      }
    } catch (_) {}
    return {};
  }

  static dynamic _getPlanMonthly(Plan plan) {
    try {
      return (plan as dynamic).monthlyContribution;
    } catch (_) {
      return 0.0;
    }
  }

  static String _getMovementTicker(dynamic m) {
    try {
      if (m is Map) {
        final v = m['ticker'] ?? m['symbol'] ?? m['etf'] ?? '';
        return (v ?? '').toString().trim().toUpperCase();
      }
      final v = (m as dynamic).ticker;
      return (v ?? '').toString().trim().toUpperCase();
    } catch (_) {
      return '';
    }
  }

  static double _getMovementAmount(dynamic m) {
    try {
      if (m is Map) {
        final v = m['amount'] ?? m['value'] ?? m['eur'] ?? 0;
        return _safeDouble(v, fallback: 0.0);
      }
      final v = (m as dynamic).amount;
      return _safeDouble(v, fallback: 0.0);
    } catch (_) {
      return 0.0;
    }
  }
}
