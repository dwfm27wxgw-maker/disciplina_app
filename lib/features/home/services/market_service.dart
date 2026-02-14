import 'dart:math' as math;

import '../../../core/models/market_quote.dart';

class MarketService {
  static Future<List<MarketQuote>> fetchQuotes(
    List<String> tickers, {
    String range = '1D', // '1D' | '1W' | '1M'
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));

    final rng = math.Random(DateTime.now().millisecondsSinceEpoch);

    int points;
    double volPercent;

    if (range == '1M') {
      points = 30;
      volPercent = 0.9; // más movimiento
    } else if (range == '1W') {
      points = 14;
      volPercent = 0.5;
    } else {
      points = 24;
      volPercent = 0.25; // 1D más suave
    }

    final out = <MarketQuote>[];

    for (final raw in tickers) {
      final t = raw.trim().toUpperCase();
      final base = 50 + rng.nextDouble() * 150;

      final history = <double>[];
      double p = base;

      for (int i = 0; i < points; i++) {
        // random walk suave
        final step = (rng.nextDouble() * 2 - 1) * volPercent / 100.0;
        p = (p * (1.0 + step)).clamp(1.0, 999999.0);
        history.add(double.parse(p.toStringAsFixed(2)));
      }

      final first = history.first;
      final last = history.last;
      final changePercent = first == 0 ? 0.0 : ((last - first) / first) * 100.0;

      out.add(
        MarketQuote(
          ticker: t,
          price: last,
          changePercent: double.parse(changePercent.toStringAsFixed(2)),
          history: history,
        ),
      );
    }

    return out;
  }
}
