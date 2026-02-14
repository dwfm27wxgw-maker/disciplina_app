// ignore_for_file: deprecated_member_use, unnecessary_string_interpolations, unnecessary_to_list_in_spreads, prefer_const_constructors
import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:disciplina_app/core/models/market_quote.dart';
import 'package:disciplina_app/core/models/plan.dart';
import 'package:disciplina_app/core/storage/local_store.dart';
import 'package:disciplina_app/core/ui/app_theme.dart';
import 'package:disciplina_app/core/ui/d_widgets.dart';

import 'package:disciplina_app/features/home/screens/add_movement_screen.dart';

class EtfDetailScreen extends StatefulWidget {
  final String ticker;
  final MarketQuote? quote;
  final Plan? plan;
  final double monthlyTarget;

  const EtfDetailScreen({
    super.key,
    required this.ticker,
    this.quote,
    this.plan,
    this.monthlyTarget = 50.0,
  });

  @override
  State<EtfDetailScreen> createState() => _EtfDetailScreenState();
}

class _EtfDetailScreenState extends State<EtfDetailScreen> {
  bool _loading = true;
  String? _error;

  List<dynamic> _all = [];
  List<dynamic> _byTicker = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final ms = await LocalStore.getMovements();
      ms.sort((a, b) => _mDateTime(b).compareTo(_mDateTime(a)));

      final t = widget.ticker.trim().toUpperCase();
      final by =
          ms.where((m) => _mTicker(m).trim().toUpperCase() == t).toList();

      setState(() {
        _all = ms;
        _byTicker = by;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ---------------------------
  // Cálculos
  // ---------------------------

  double _sumAmount(List<dynamic> ms) {
    double sum = 0.0;
    for (final m in ms) {
      sum += _mAmount(m);
    }
    return sum;
  }

  bool _isSameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  double _monthInvestedForTicker(DateTime now) {
    return _sumAmount(
      _byTicker.where((m) => _isSameMonth(_mDateTime(m), now)).toList(),
    );
  }

  double _monthInvestedTotal(DateTime now) {
    return _sumAmount(
      _all.where((m) => _isSameMonth(_mDateTime(m), now)).toList(),
    );
  }

  Map<String, double> _planWeights() {
    final out = <String, double>{};
    final p = widget.plan;
    if (p == null) return out;

    try {
      final dynamic raw = (p as dynamic).targetWeights;
      if (raw is Map) {
        raw.forEach((k, v) {
          if (k == null) return;
          final key = k.toString().trim().toUpperCase();
          final val = _asDouble(v);
          if (key.isNotEmpty && val > 0) out[key] = val;
        });
      }
    } catch (_) {}

    return out;
  }

  double _weightForTicker(String t) {
    final weights = _planWeights();
    if (weights.isEmpty) return 0.0;

    final total = weights.values.fold<double>(0.0, (p, e) => p + e);
    if (total <= 0) return 0.0;

    final w = weights[t.toUpperCase()] ?? 0.0;
    return w / total;
  }

  double _suggestedAmount(DateTime now) {
    final w = _weightForTicker(widget.ticker);
    if (w <= 0) return 0.0;

    final investedTotal = _monthInvestedTotal(now);
    final remaining = math.max(0.0, widget.monthlyTarget - investedTotal);

    final targetForThis = remaining * w;
    return targetForThis.isFinite ? targetForThis : 0.0;
  }

  // ---------------------------
  // UI
  // ---------------------------

  @override
  Widget build(BuildContext context) {
    final t = widget.ticker.toUpperCase();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text(t),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null)
              ? Center(
                  child: Text(_error!,
                      style: const TextStyle(color: AppTheme.muted)))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final now = DateTime.now();
    final t = widget.ticker.toUpperCase();

    final quote = widget.quote;
    final price = quote?.price;
    final change = quote?.changePercent;

    final investedTickerTotal = _sumAmount(_byTicker);
    final investedTickerMonth = _monthInvestedForTicker(now);

    final investedTotalMonth = _monthInvestedTotal(now);
    final remainingMonth =
        math.max(0.0, widget.monthlyTarget - investedTotalMonth);

    final w = _weightForTicker(t);
    final targetPct = (w * 100.0);
    final monthPct = investedTotalMonth <= 0
        ? 0.0
        : (investedTickerMonth / investedTotalMonth) * 100.0;

    final suggested = _suggestedAmount(now);

    final up = (change ?? 0) >= 0;
    final changeColor = up ? AppTheme.green : AppTheme.red;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        DCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DTitle(t, size: 20),
                      const SizedBox(height: 6),
                      if (price != null)
                        Row(
                          children: [
                            DMuted('Precio'),
                            const SizedBox(width: 8),
                            DText('${price.toStringAsFixed(2)}'),
                            const SizedBox(width: 10),
                            if (change != null) ...[
                              Icon(
                                up
                                    ? Icons.arrow_drop_up_rounded
                                    : Icons.arrow_drop_down_rounded,
                                color: changeColor,
                              ),
                              Text(
                                '${change.abs().toStringAsFixed(2)}%',
                                style: TextStyle(
                                    color: changeColor,
                                    fontWeight: FontWeight.w900),
                              ),
                            ],
                          ],
                        )
                      else
                        const DMuted(
                            'Sin datos de mercado (mock o no cargado).'),
                    ]),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () async {
                  final amount = suggested > 0.01 ? suggested : 0.0;
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AddMovementScreen(
                        presetTicker: t,
                        presetAmount: amount > 0 ? amount : null,
                      ),
                    ),
                  );
                  _reload();
                },
                child: Text(suggested > 0.01
                    ? 'Comprar ${suggested.toStringAsFixed(0)}€'
                    : 'Comprar'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        DCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              children: [
                const DTitle('Este mes', size: 16),
                const Spacer(),
                DPill('Restante ${remainingMonth.toStringAsFixed(0)}€'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _statBox(
                    title: 'Invertido (ticker)',
                    value: '${investedTickerMonth.toStringAsFixed(2)} €',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _statBox(
                    title: 'Total mes',
                    value: '${investedTotalMonth.toStringAsFixed(2)} €',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (targetPct > 0) ...[
              DMuted(
                  'Objetivo plan: ${targetPct.toStringAsFixed(0)}% • Actual mes: ${monthPct.toStringAsFixed(0)}%'),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: (targetPct <= 0)
                      ? 0
                      : (monthPct / targetPct).clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: Colors.white.withOpacity(0.06),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    monthPct >= targetPct ? AppTheme.green : AppTheme.accent,
                  ),
                ),
              ),
            ] else
              const DMuted('Define pesos en Plan para ver objetivo vs actual.'),
          ]),
        ),
        const SizedBox(height: 12),
        DCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const DTitle('Historial (ticker)', size: 16),
            const SizedBox(height: 10),
            if (_byTicker.isEmpty)
              const DMuted('Aún no hay compras de este ticker.')
            else
              ..._byTicker.take(30).map((m) {
                final dt = _mDateTime(m);
                final amount = _mAmount(m);
                final note = _mNote(m);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      DPill(_dateShort(dt)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          note.isEmpty ? 'Compra' : note,
                          style: const TextStyle(
                              color: AppTheme.muted,
                              fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${amount.toStringAsFixed(2)} €',
                        style: const TextStyle(
                            color: AppTheme.text, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                );
              }).toList(),
            const SizedBox(height: 6),
            DMuted(
                'Total histórico ticker: ${investedTickerTotal.toStringAsFixed(2)} €'),
          ]),
        ),
      ],
    );
  }

  Widget _statBox({required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                color: AppTheme.muted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(
                color: AppTheme.text, fontWeight: FontWeight.w900)),
      ]),
    );
  }

  // ---------------------------
  // Helpers tolerantes
  // ---------------------------

  String _mTicker(dynamic m) {
    try {
      if (m is Map) return (m['ticker'] ?? '').toString();
      final d = m as dynamic;
      return (d.ticker ?? '').toString();
    } catch (_) {
      return '';
    }
  }

  double _mAmount(dynamic m) {
    try {
      if (m is Map) return _asDouble(m['amount']);
      final d = m as dynamic;
      return _asDouble(d.amount);
    } catch (_) {
      return 0.0;
    }
  }

  DateTime _mDateTime(dynamic m) {
    try {
      dynamic v;
      if (m is Map) {
        v = m['date'];
      } else {
        final d = m as dynamic;
        v = d.date;
      }
      if (v is DateTime) return v;
      final s = (v ?? '').toString();
      return DateTime.tryParse(s) ?? DateTime.fromMillisecondsSinceEpoch(0);
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  String _mNote(dynamic m) {
    try {
      if (m is Map) return (m['note'] ?? '').toString().trim();
      final d = m as dynamic;
      return (d.note ?? '').toString().trim();
    } catch (_) {
      return '';
    }
  }

  double _asDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '.')) ?? 0.0;
  }

  String _dateShort(DateTime dt) {
    String two(int x) => x.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year}';
  }
}
