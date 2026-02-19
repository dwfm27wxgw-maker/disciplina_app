import 'dart:math' as math;

import '../../../core/models/market_quote.dart';

class MarketService {
  static Future<List<MarketQuote>> fetchQuotes(List<String> tickers) async {
    final rng = math.Random(DateTime.now().millisecondsSinceEpoch);

    return tickers.map((t) {
      final base = 10 + rng.nextDouble() * 200;
      final ch = (rng.nextDouble() * 2 - 1) * 2.5; // -2.5%..+2.5%
      return MarketQuote(
        ticker: t.toUpperCase(),
        price: double.parse(base.toStringAsFixed(2)),
        changePercent: double.parse(ch.toStringAsFixed(2)),
      );
    }).toList();
  }
}
