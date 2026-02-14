class Movement {
  final String id;
  final String ticker;
  final double amount;
  final DateTime date;

  const Movement({
    required this.id,
    required this.ticker,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'ticker': ticker,
        'amount': amount,
        'date': date.toIso8601String(),
      };

  factory Movement.fromJson(Map<String, dynamic> json) {
    return Movement(
      id: (json['id'] ?? '').toString(),
      ticker: (json['ticker'] ?? '').toString(),
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : double.tryParse((json['amount'] ?? '0').toString()) ?? 0.0,
      date: DateTime.tryParse((json['date'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
