class MonthlyDigest {
  final String monthKey; // "YYYY-MM"
  final double monthlyContribution;

  final double totalInvested;
  final double investedThisMonth;

  final Map<String, double> targetWeights; // 0..1
  final Map<String, double> currentWeights; // 0..1 (histórico)
  final Map<String, double> deltaVsTarget; // current - target (pp en 0..1)

  final Map<String, double> recommendedEuros; // recomendado para este mes

  const MonthlyDigest({
    required this.monthKey,
    required this.monthlyContribution,
    required this.totalInvested,
    required this.investedThisMonth,
    required this.targetWeights,
    required this.currentWeights,
    required this.deltaVsTarget,
    required this.recommendedEuros,
  });
}
