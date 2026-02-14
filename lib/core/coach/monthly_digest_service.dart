import '../models/plan.dart';
import '../storage/local_store.dart';

class MonthlySuggestion {
  final String ticker;
  final double amountEur;
  final String reason;

  const MonthlySuggestion({
    required this.ticker,
    required this.amountEur,
    required this.reason,
  });
}

class MonthlyDigestResult {
  final int year;
  final int month;

  final double baseMonthlyTargetEur;
  final double marketChangePercent;
  final double budgetMultiplier;
  final double monthlyTargetEur;

  final double investedThisMonthEur;
  final double remainingEur;

  final bool isCompleteByMath;
  final List<MonthlySuggestion> suggestions;

  const MonthlyDigestResult({
    required this.year,
    required this.month,
    required this.baseMonthlyTargetEur,
    required this.marketChangePercent,
    required this.budgetMultiplier,
    required this.monthlyTargetEur,
    required this.investedThisMonthEur,
    required this.remainingEur,
    required this.isCompleteByMath,
    required this.suggestions,
  });
}

class MonthlyDigestService {
  // ✅ Modo SUAVE: 0.90x–1.10x
  static double computeBudgetMultiplier(
    double marketChangePercent, {
    double k = 0.03,
    double min = 0.90,
    double max = 1.10,
  }) {
    final raw = 1.0 - (k * marketChangePercent);
    final clamped = raw.clamp(min, max);
    return clamped.toDouble();
  }

  static MonthlyDigestResult generate({
    required int year,
    required int month,
    required Plan? plan,
    required List<dynamic> movements,
    double marketChangePercent = 0.0,
    bool marketBalanceEnabled = true,
  }) {
    final baseTarget = (plan?.monthlyContribution ?? 50.0).toDouble();

    final multiplier = marketBalanceEnabled
        ? computeBudgetMultiplier(marketChangePercent)
        : 1.0;

    final target = double.parse((baseTarget * multiplier).toStringAsFixed(2));

    final byTicker = <String, double>{};
    double invested = 0.0;

    for (final raw in movements) {
      final m = LocalStore.tryParseMovement(raw);
      if (m == null) continue;

      if (m.date.year == year && m.date.month == month) {
        invested += m.amount;
        byTicker[m.ticker] = (byTicker[m.ticker] ?? 0.0) + m.amount;
      }
    }

    final remaining = target - invested;
    final remainingClamped = remaining <= 0 ? 0.0 : remaining;

    final weights = plan?.targetWeights ?? <String, double>{};
    if (weights.isEmpty) {
      return MonthlyDigestResult(
        year: year,
        month: month,
        baseMonthlyTargetEur: baseTarget,
        marketChangePercent: marketChangePercent,
        budgetMultiplier: multiplier,
        monthlyTargetEur: target,
        investedThisMonthEur: invested,
        remainingEur: remainingClamped,
        isCompleteByMath: remainingClamped <= 0.0001,
        suggestions: const [],
      );
    }

    final sumW = weights.values.fold<double>(0, (a, b) => a + b);
    final norm = <String, double>{};
    for (final e in weights.entries) {
      final w = (sumW <= 0.0001) ? 0.0 : (e.value / sumW);
      if (w > 0) norm[e.key.toUpperCase()] = w;
    }

    if (remainingClamped <= 0.0001) {
      return MonthlyDigestResult(
        year: year,
        month: month,
        baseMonthlyTargetEur: baseTarget,
        marketChangePercent: marketChangePercent,
        budgetMultiplier: multiplier,
        monthlyTargetEur: target,
        investedThisMonthEur: invested,
        remainingEur: 0.0,
        isCompleteByMath: true,
        suggestions: const [],
      );
    }

    final deficit = <String, double>{};
    for (final e in norm.entries) {
      final t = e.key;
      final ideal = target * e.value;
      final have = byTicker[t] ?? 0.0;
      final d = ideal - have;
      deficit[t] = d > 0 ? d : 0.0;
    }

    final sumDef = deficit.values.fold<double>(0, (a, b) => a + b);

    final allocations = <String, double>{};
    if (sumDef > 0.0001) {
      for (final e in deficit.entries) {
        if (e.value <= 0) continue;
        allocations[e.key] = remainingClamped * (e.value / sumDef);
      }
    } else {
      for (final e in norm.entries) {
        allocations[e.key] = remainingClamped * e.value;
      }
    }

    final sorted = allocations.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(3).toList();

    double used = 0.0;
    final sug = <MonthlySuggestion>[];

    for (int i = 0; i < top.length; i++) {
      final t = top[i].key;
      double amt = double.parse(top[i].value.toStringAsFixed(2));

      if (i == top.length - 1) {
        final fix = remainingClamped - used;
        amt = double.parse(fix.toStringAsFixed(2));
      }

      if (amt <= 0) continue;
      used += amt;

      sug.add(
        MonthlySuggestion(
          ticker: t,
          amountEur: amt,
          reason: 'Pesos objetivo + factor mercado (suave).',
        ),
      );
    }

    return MonthlyDigestResult(
      year: year,
      month: month,
      baseMonthlyTargetEur: baseTarget,
      marketChangePercent: marketChangePercent,
      budgetMultiplier: multiplier,
      monthlyTargetEur: target,
      investedThisMonthEur: invested,
      remainingEur: remainingClamped,
      isCompleteByMath: remainingClamped <= 0.0001,
      suggestions: sug,
    );
  }
}
