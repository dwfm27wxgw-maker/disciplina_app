class MarketQuote {
  final String ticker;
  final double price;
  final double changePercent;

  /// Serie corta de precios para dibujar la sparkline (20–40 puntos).
  final List<double> history;

  MarketQuote({
    required this.ticker,
    required this.price,
    required this.changePercent,
    required this.history,
  });

  MarketQuote copyWith({
    String? ticker,
    double? price,
    double? changePercent,
    List<double>? history,
  }) {
    return MarketQuote(
      ticker: ticker ?? this.ticker,
      price: price ?? this.price,
      changePercent: changePercent ?? this.changePercent,
      history: history ?? this.history,
    );
  }

  Map<String, dynamic> toJson() => {
        'ticker': ticker,
        'price': price,
        'changePercent': changePercent,
        'history': history,
      };

  static MarketQuote fromJson(Map<String, dynamic> json) {
    final rawHistory = (json['history'] as List?) ?? const [];
    return MarketQuote(
      ticker: (json['ticker'] ?? '').toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      changePercent: (json['changePercent'] as num?)?.toDouble() ?? 0.0,
      history: rawHistory.map((e) => (e as num).toDouble()).toList(),
    );
  }
}
