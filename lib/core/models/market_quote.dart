class MarketQuote {
  final String ticker;
  final double price;
  final double changePercent;

  const MarketQuote({
    required this.ticker,
    required this.price,
    required this.changePercent,
  });
}
