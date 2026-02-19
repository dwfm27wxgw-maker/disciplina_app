import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/market_quote.dart';
import '../../../core/models/plan.dart';
import '../../../core/storage/local_store.dart';
import '../../../core/services/notification_service.dart'; // ✅ RUTA CORRECTA
import '../../coach/screens/monthly_digest_screen.dart';

import '../../movements/screens/import_revolut_csv_screen.dart';
import '../../plan/screens/edit_plan_screen.dart';
import '../services/market_service.dart';
import 'add_movement_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _loading = true;
  String? _error;

  Plan? _plan;

  List<String> _tickers = [];
  List<MarketQuote> _quotes = [];
  List<dynamic> _movements = [];

  // Anim “premium” (cascada). Re-seed para reanimar al recargar.
  int _animSeed = 0;
  static const int _animBaseDelayMs = 60;

  @override
  void initState() {
    super.initState();
    _reloadAll();
  }

  Future<void> _reloadAll() async {
    setState(() {
      _loading = true;
      _error = null;
      _animSeed++;
    });

    try {
      // ✅ Tickers
      List<String> tickers = [];
      try {
        final t = await LocalStore.getTickers();
        if (t is List<String>) tickers = t;
      } catch (_) {}

      // ✅ Plan
      Plan? plan;
      try {
        final p = await LocalStore.getPlan();
        if (p is Plan) plan = p;
      } catch (_) {}

      // ✅ Movimientos
      List<dynamic> movements = [];
      try {
        final m = await LocalStore.getMovements();
        if (m is List) movements = List<dynamic>.from(m);
      } catch (_) {}

      // ✅ Quotes (si falla, seguimos con lista vacía)
      List<MarketQuote> quotes = [];
      try {
        if (tickers.isNotEmpty) {
          final q = await MarketService.fetchQuotes(tickers);
          if (q is List<MarketQuote>) quotes = q;
        }
      } catch (_) {}

      setState(() {
        _tickers = tickers;
        _plan = plan;
        _movements = movements;
        _quotes = quotes;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ✅ NUEVO: abrir coach
  Future<void> _openCoach() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MonthlyDigestScreen()),
    );
    await _reloadAll();
  }

  // ✅ NUEVO: long press oculto en el título => notificación instantánea de test
  Future<void> _testCoachNotificationNow() async {
    try {
      await NotificationService.showMonthlyCoachNow();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notificación de prueba enviada')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error test notificación: $e')),
      );
    }
  }

  // -----------------------------
  // Helpers tolerantes (Map/obj)
  // -----------------------------
  dynamic _get(dynamic obj, String key) {
    try {
      if (obj is Map) return obj[key];
      // ignore: avoid_dynamic_calls
      return (obj as dynamic)[key];
    } catch (_) {
      try {
        // ignore: avoid_dynamic_calls
        return (obj as dynamic).toJson()[key];
      } catch (_) {
        return null;
      }
    }
  }

  String _s(dynamic v, [String fallback = '']) {
    if (v == null) return fallback;
    final str = v.toString().trim();
    return str.isEmpty ? fallback : str;
  }

  double _d(dynamic v, [double fallback = 0.0]) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    final s = v.toString().replaceAll(',', '.').trim();
    return double.tryParse(s) ?? fallback;
  }

  DateTime _dt(dynamic v, [DateTime? fallback]) {
    fallback ??= DateTime.now();
    if (v == null) return fallback;
    if (v is DateTime) return v;
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return fallback;
    }
  }

  String _fmtMoney(double v) {
    final sign = v < 0 ? '-' : '';
    final a = v.abs();
    return '$sign${a.toStringAsFixed(2)}€';
  }

  String _fmtDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }

  bool _isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  // -----------------------------
  // Cálculos cartera
  // -----------------------------
  double _monthlyTarget() {
    try {
      final p = _plan;
      if (p != null) {
        // ignore: avoid_dynamic_calls
        final v = (p as dynamic).monthlyContribution;
        final d = _d(v, 0);
        if (d > 0) return d;
      }
    } catch (_) {}
    return 50.0;
  }

  double _investedThisMonth() {
    final now = DateTime.now();
    double sum = 0;
    for (final m in _movements) {
      final date = _dt(_get(m, 'date'));
      if (_isSameMonth(date, now)) {
        sum += _d(_get(m, 'amount'), 0);
      }
    }
    return sum;
  }

  Map<String, double> _actualByTickerAllTime() {
    final map = <String, double>{};
    for (final m in _movements) {
      final t = _s(_get(m, 'ticker')).toUpperCase();
      if (t.isEmpty) continue;
      map[t] = (map[t] ?? 0) + _d(_get(m, 'amount'), 0);
    }
    return map;
  }

  double _totalInvestedAllTime() {
    double sum = 0;
    for (final m in _movements) {
      sum += _d(_get(m, 'amount'), 0);
    }
    return sum;
  }

  Map<String, double> _targetWeights() {
    try {
      final p = _plan;
      if (p != null) {
        // ignore: avoid_dynamic_calls
        final tw = (p as dynamic).targetWeights;
        if (tw is Map) {
          final out = <String, double>{};
          tw.forEach((k, v) => out[_s(k).toUpperCase()] = _d(v, 0));
          final sum = out.values.fold<double>(0, (a, b) => a + b);
          if (sum > 1.5) {
            out.updateAll((k, v) => v / 100.0);
          }
          return out;
        }
      }
    } catch (_) {}

    final tickers = _tickers.isNotEmpty ? _tickers : ['IWDA', 'EIMI', 'AGGH'];
    final w = 1.0 / tickers.length;
    return {for (final t in tickers) t.toUpperCase(): w};
  }

  List<_BuyRow> _computeBuyThisMonth({int top = 3}) {
    final investedThisMonth = _investedThisMonth();
    final remaining = (_monthlyTarget() - investedThisMonth).clamp(0.0, 1e9);

    final actual = _actualByTickerAllTime();
    final weights = _targetWeights();

    final totalInvested = actual.values.fold<double>(0, (a, b) => a + b);
    final safeTotal = totalInvested <= 0 ? 1.0 : totalInvested;

    final rows = <_BuyRow>[];

    for (final entry in weights.entries) {
      final t = entry.key.toUpperCase();
      final targetW = entry.value;
      final currentAmt = actual[t] ?? 0.0;
      final currentW = currentAmt / safeTotal;
      final deficitW = (targetW - currentW);

      rows.add(_BuyRow(
        ticker: t,
        deficitWeight: deficitW,
        suggested: 0.0,
      ));
    }

    rows.sort((a, b) => b.deficitWeight.compareTo(a.deficitWeight));

    final positives = rows.where((r) => r.deficitWeight > 0).toList();
    final denom = positives.fold<double>(0, (s, r) => s + r.deficitWeight);

    if (remaining > 0 && denom > 0) {
      for (final r in rows) {
        if (r.deficitWeight <= 0) {
          r.suggested = 0;
          continue;
        }
        final share = r.deficitWeight / denom;
        r.suggested = (remaining * share);
      }
    }

    return rows.take(top).toList();
  }

  String _monthlyCoachMessage() {
    final invested = _investedThisMonth();
    final target = _monthlyTarget();
    final remaining = (target - invested).clamp(0.0, 1e9);
    final recs = _computeBuyThisMonth(top: 2);

    final monthDone = remaining <= 0.0001;

    if (monthDone) {
      return '✅ Mes completado. Has invertido ${_fmtMoney(invested)} este mes.\n'
          'Mantén el plan y prepárate para el próximo mes.';
    }

    final best = recs.isNotEmpty ? recs.first : null;
    if (best == null) {
      return 'Te quedan ${_fmtMoney(remaining)} este mes.\n'
          'No hay recomendación clara: revisa tu Plan.';
    }

    final amt = best.suggested <= 0 ? remaining : best.suggested;
    return 'Te quedan ${_fmtMoney(remaining)} este mes.\n'
        'Prioridad: ${best.ticker} → aprox. ${_fmtMoney(amt)} para acercarte al objetivo.';
  }

  bool _monthCompleted() {
    final remaining = (_monthlyTarget() - _investedThisMonth()).clamp(0.0, 1e9);
    return remaining <= 0.0001;
  }

  // -----------------------------
  // Acciones UI
  // -----------------------------
  Future<void> _openPlan() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EditPlanScreen()),
    );
    await _reloadAll();
  }

  Future<void> _openImportCsv() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ImportRevolutCsvScreen()),
    );
    await _reloadAll();
  }

  Future<void> _openAddMovement(
      {String? presetTicker, double? presetAmount}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddMovementScreen(
          presetTicker: presetTicker,
          presetAmount: presetAmount,
        ),
      ),
    );
    await _reloadAll();
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copiado')),
    );
  }

  // -----------------------------
  // UI helpers (cards, chips, anim)
  // -----------------------------
  Widget _appear({required int i, required Widget child}) {
    final ms = _animBaseDelayMs * i;
    final seed = _animSeed;
    return FutureBuilder<void>(
      future:
          Future<void>.delayed(Duration(milliseconds: ms + (seed % 7) * 10)),
      builder: (context, snap) {
        final show = snap.connectionState == ConnectionState.done;
        return AnimatedOpacity(
          opacity: show ? 1 : 0,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
          child: AnimatedSlide(
            offset: show ? Offset.zero : const Offset(0, 0.03),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
            child: child,
          ),
        );
      },
    );
  }

  Widget _card({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(14),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _chip(String text, {bool good = false, bool warn = false}) {
    Color bg = Colors.white.withOpacity(0.06);
    Color fg = Colors.white.withOpacity(0.78);

    if (good) {
      bg = const Color(0xFF34C759).withOpacity(0.16);
      fg = const Color(0xFF34C759);
    } else if (warn) {
      bg = const Color(0xFFFFCC00).withOpacity(0.16);
      fg = const Color(0xFFFFCC00);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Row(
      children: [
        Expanded(
          child: Text(
            k,
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          v,
          style: TextStyle(
            color: Colors.white.withOpacity(0.90),
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _bar({
    required double value01,
    required bool good,
  }) {
    final v = value01.clamp(0.0, 1.0);
    final Color fill = good ? const Color(0xFF34C759) : const Color(0xFFFF3B30);

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 10,
        color: Colors.white.withOpacity(0.06),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: v,
            child: Container(color: fill.withOpacity(0.85)),
          ),
        ),
      ),
    );
  }

  // -----------------------------
  // UI blocks que te faltaban
  // -----------------------------
  Widget _buildSkeleton() {
    Widget box({double h = 14, double w = double.infinity}) => Container(
          height: h,
          width: w,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
          ),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              box(h: 18, w: 200),
              const SizedBox(height: 10),
              box(h: 12),
              const SizedBox(height: 8),
              box(h: 12, w: 260),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: box(h: 38)),
                  const SizedBox(width: 10),
                  Expanded(child: box(h: 38)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _card(
            child: Column(children: [
          box(h: 14),
          const SizedBox(height: 8),
          box(h: 14),
          const SizedBox(height: 8),
          box(h: 14)
        ])),
        const SizedBox(height: 12),
        _card(
            child: Column(children: [
          box(h: 14),
          const SizedBox(height: 8),
          box(h: 14),
          const SizedBox(height: 8),
          box(h: 14)
        ])),
      ],
    );
  }

  Widget _buildError(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: 10),
            Text(msg, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _reloadAll,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard() {
    final done = _monthCompleted();
    final msg = _monthlyCoachMessage();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                done ? 'Coach del mes' : 'Acción del mes ★',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.92),
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              _chip(done ? 'Completado' : 'En curso', good: done),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            msg,
            style: TextStyle(
              color: Colors.white.withOpacity(0.82),
              height: 1.25,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openCoach,
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text('Ver coach'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final recs = _computeBuyThisMonth(top: 1);
                    final best = recs.isNotEmpty ? recs.first : null;
                    final invested = _investedThisMonth();
                    final remaining =
                        (_monthlyTarget() - invested).clamp(0.0, 1e9);

                    _openAddMovement(
                      presetTicker: best?.ticker,
                      presetAmount: (best != null && best.suggested > 0)
                          ? best.suggested
                          : remaining,
                    );
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Registrar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSummaryCard() {
    final target = _monthlyTarget();
    final invested = _investedThisMonth();
    final remaining = (target - invested).clamp(0.0, 1e9);
    final pct = (target <= 0) ? 0.0 : (invested / target).clamp(0.0, 1.0);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Resumen del mes',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.92),
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              _chip('${(pct * 100).round()}%'),
            ],
          ),
          const SizedBox(height: 12),
          _kv('Objetivo', _fmtMoney(target)),
          const SizedBox(height: 8),
          _kv('Invertido', _fmtMoney(invested)),
          const SizedBox(height: 8),
          _kv('Restante', _fmtMoney(remaining)),
          const SizedBox(height: 12),
          _bar(value01: pct, good: remaining <= 0.0001),
        ],
      ),
    );
  }

  Widget _buildTargetVsActualCard() {
    final weights = _targetWeights();
    final actual = _actualByTickerAllTime();
    final total = actual.values.fold<double>(0, (a, b) => a + b);
    final safeTotal = total <= 0 ? 1.0 : total;

    // Estado simple
    double maxAbsDelta = 0;
    for (final t in weights.keys) {
      final wT = weights[t] ?? 0.0;
      final wA = (actual[t] ?? 0.0) / safeTotal;
      maxAbsDelta = math.max(maxAbsDelta, (wT - wA).abs());
    }

    final bool ok = maxAbsDelta < 0.05;
    final bool warn = maxAbsDelta >= 0.05 && maxAbsDelta < 0.12;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Objetivo vs Actual',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.92),
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              _chip(ok ? 'Mantener' : (warn ? 'Ajustar' : 'Rebalanceo'),
                  good: ok, warn: warn && !ok),
            ],
          ),
          const SizedBox(height: 12),
          ...weights.entries.map((e) {
            final t = e.key.toUpperCase();
            final wT = e.value;
            final wA = (actual[t] ?? 0.0) / safeTotal;
            final delta = (wT - wA);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        t,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.90),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Obj ${(wT * 100).toStringAsFixed(0)}% · Act ${(wA * 100).toStringAsFixed(0)}% · Δ ${(delta * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.65),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _bar(value01: wA, good: delta.abs() < 0.05),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBuyThisMonthCard() {
    final invested = _investedThisMonth();
    final target = _monthlyTarget();
    final remaining = (target - invested).clamp(0.0, 1e9);

    final recs = _computeBuyThisMonth(top: 3);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Qué comprar este mes',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.92),
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              _chip(
                  remaining <= 0.0001
                      ? 'Mes completado'
                      : 'Restante ${_fmtMoney(remaining)}',
                  good: remaining <= 0.0001),
            ],
          ),
          const SizedBox(height: 10),
          if (remaining <= 0.0001)
            Text(
              '✅ Ya has completado tu presupuesto del mes.\n'
              'Disciplina: mantiene el plan, sin perseguir el precio.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.78),
                height: 1.25,
                fontWeight: FontWeight.w600,
              ),
            )
          else ...[
            Text(
              'Top prioridades (según desviación del Plan):',
              style: TextStyle(
                color: Colors.white.withOpacity(0.78),
                height: 1.25,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            ...recs.map((r) {
              final suggested = (r.suggested > 0) ? r.suggested : remaining;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Text(
                        r.ticker,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.90),
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Sugerido: ${_fmtMoney(suggested)}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.82),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () => _openAddMovement(
                        presetTicker: r.ticker,
                        presetAmount: suggested,
                      ),
                      child: const Text('Comprar'),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildMarketCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Mercado hoy',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.92),
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              _chip('1D'),
            ],
          ),
          const SizedBox(height: 12),
          if (_tickers.isEmpty)
            Text(
              'Sin tickers. Configura tu Plan o añade tickers.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontWeight: FontWeight.w600,
              ),
            )
          else if (_quotes.isEmpty)
            Text(
              'No hay datos de mercado ahora mismo (o el servicio está en modo mock).',
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontWeight: FontWeight.w600,
              ),
            )
          else
            ..._quotes.map((q) {
              final ch = q.changePercent;
              final good = ch >= 0;
              final c =
                  good ? const Color(0xFF34C759) : const Color(0xFFFF3B30);

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () => _copyToClipboard('${q.ticker} ${q.price}'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: Row(
                      children: [
                        Text(
                          q.ticker,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.92),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          q.price.toStringAsFixed(2),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: c.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: c.withOpacity(0.35)),
                          ),
                          child: Text(
                            '${ch >= 0 ? '+' : ''}${ch.toStringAsFixed(2)}%',
                            style: TextStyle(
                              color: c,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildMovementsCard() {
    final items = List<dynamic>.from(_movements);
    items.sort((a, b) {
      final da = _dt(_get(a, 'date'));
      final db = _dt(_get(b, 'date'));
      return db.compareTo(da);
    });
    final top = items.take(6).toList();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Últimas compras',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.92),
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              _chip('${_movements.length}'),
            ],
          ),
          const SizedBox(height: 12),
          if (top.isEmpty)
            Text(
              'Aún no hay compras registradas.\nPulsa “Registrar” para añadir la primera.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                height: 1.25,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            ...top.map((m) {
              final t = _s(_get(m, 'ticker'), '—').toUpperCase();
              final a = _d(_get(m, 'amount'), 0);
              final d = _dt(_get(m, 'date'));
              final note = _s(_get(m, 'note'));

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () =>
                      _copyToClipboard('$t ${_fmtMoney(a)} ${_fmtDate(d)}'),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: Row(
                      children: [
                        Text(
                          t,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.92),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _fmtMoney(a),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _fmtDate(d),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.60),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        if (note.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          Icon(Icons.notes_rounded,
                              size: 16, color: Colors.white.withOpacity(0.55)),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openAddMovement(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Registrar compra'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -----------------------------
  // build
  // -----------------------------
  @override
  Widget build(BuildContext context) {
    final hasInvestments = _totalInvestedAllTime() > 0.0001;

    return Scaffold(
      backgroundColor: const Color(0xFF0E1013),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1013),
        elevation: 0,
        titleSpacing: 14,
        title: GestureDetector(
          onLongPress: _testCoachNotificationNow, // ✅ oculto
          child: Row(
            children: [
              Text(
                'Disciplina',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.92),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Text(
                  'Hoy',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontWeight: FontWeight.w800,
                      fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Coach',
            onPressed: _openCoach,
            icon: const Icon(Icons.chat_bubble_outline_rounded),
          ),
          IconButton(
            tooltip: 'Plan',
            onPressed: _openPlan,
            icon: const Icon(Icons.tune_rounded),
          ),
          IconButton(
            tooltip: 'Importar CSV',
            onPressed: _openImportCsv,
            icon: const Icon(Icons.upload_file_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? _buildSkeleton()
          : (_error != null)
              ? _buildError(_error!)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
                  children: [
                    _appear(i: 0, child: _buildActionCard()),
                    const SizedBox(height: 12),
                    _appear(i: 1, child: _buildMonthSummaryCard()),
                    if (hasInvestments) ...[
                      const SizedBox(height: 12),
                      _appear(i: 2, child: _buildTargetVsActualCard()),
                    ],
                    const SizedBox(height: 12),
                    _appear(i: 3, child: _buildBuyThisMonthCard()),
                    const SizedBox(height: 12),
                    _appear(i: 4, child: _buildMarketCard()),
                    const SizedBox(height: 12),
                    _appear(i: 5, child: _buildMovementsCard()),
                  ],
                ),
      floatingActionButton: null,
    );
  }
}

// -----------------------------
// Model para recomendaciones
// -----------------------------
class _BuyRow {
  _BuyRow(
      {required this.ticker,
      required this.deficitWeight,
      required this.suggested});

  final String ticker;
  final double deficitWeight;
  double suggested;
}
