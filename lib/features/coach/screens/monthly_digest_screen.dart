import 'package:flutter/material.dart';

import '../../../core/coach/monthly_digest_service.dart';
import '../../../core/models/market_quote.dart';
import '../../../core/models/plan.dart';
import '../../../core/storage/local_store.dart';
import '../../../core/storage/local_store_monthly.dart';
import '../../home/screens/add_movement_screen.dart';
import '../../home/services/market_service.dart';

class MonthlyDigestScreen extends StatefulWidget {
  const MonthlyDigestScreen({super.key});

  @override
  State<MonthlyDigestScreen> createState() => _MonthlyDigestScreenState();
}

class _MonthlyDigestScreenState extends State<MonthlyDigestScreen> {
  bool _loading = true;
  String? _error;

  Plan? _plan;
  List<dynamic> _movements = const [];
  List<MarketQuote> _quotes = const [];

  MonthlyDigestResult? _digest;
  bool _completed = false;

  bool _marketBalanceEnabled = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  double _avgMarketChangePercent(List<MarketQuote> quotes) {
    if (quotes.isEmpty) return 0.0;
    double sum = 0.0;
    for (final q in quotes) {
      sum += q.changePercent;
    }
    return sum / quotes.length;
  }

  Future<void> _openRegister(String ticker, double amount) async {
    final res = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddMovementScreen(
          presetTicker: ticker,
          presetAmount: amount,
        ),
      ),
    );

    if (res == true) {
      await _load();
    }
  }

  Future<void> _setMarketBalanceEnabled(bool v) async {
    await LocalStoreMonthly.setMarketBalanceEnabled(v);
    if (!mounted) return;
    setState(() => _marketBalanceEnabled = v);
    await _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final now = DateTime.now();
      final year = now.year;
      final month = now.month;

      final enabled = await LocalStoreMonthly.getMarketBalanceEnabled();

      final plan = await LocalStore.getPlan();
      final movements = await LocalStore.getMovements();

      final tickers = (plan?.targetWeights.keys.isNotEmpty ?? false)
          ? plan!.targetWeights.keys.map((e) => e.toUpperCase()).toList()
          : <String>['IWLE', 'EIMI', 'AGGH'];

      // ✅ Mercado 1M (estable para coach mensual)
      List<MarketQuote> quotes = const [];
      try {
        quotes = await MarketService.fetchQuotes(tickers, range: '1M');
      } catch (_) {}

      final marketAvg = _avgMarketChangePercent(quotes);

      final digest = MonthlyDigestService.generate(
        year: year,
        month: month,
        plan: plan,
        movements: movements,
        marketChangePercent: marketAvg,
        marketBalanceEnabled: enabled, // ✅ ON/OFF
      );

      final storedCompleted =
          await LocalStoreMonthly.isMonthCompleted(year, month);
      final completed = digest.isCompleteByMath || storedCompleted;

      await LocalStoreMonthly.setMonthSeen(year, month);

      if (!mounted) return;
      setState(() {
        _plan = plan;
        _movements = movements;
        _quotes = quotes;
        _digest = digest;
        _completed = completed;
        _marketBalanceEnabled = enabled;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _toggleCompleted(bool v) async {
    final d = _digest;
    if (d == null) return;
    await LocalStoreMonthly.setMonthCompleted(d.year, d.month, v);
    if (!mounted) return;
    setState(() => _completed = v);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mensaje del mes'),
        actions: [
          IconButton(
            tooltip: 'Recargar',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null)
              ? _ErrorView(error: _error!, onRetry: _load)
              : _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    final d = _digest!;
    final monthName = _monthNameEs(d.month);

    final remaining = d.remainingEur;
    final remainingText =
        (remaining <= 0) ? '0,00€' : '${remaining.toStringAsFixed(2)}€';

    final marketText = '${d.marketChangePercent.toStringAsFixed(2)}%';
    final multText = '${d.budgetMultiplier.toStringAsFixed(2)}x';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$monthName ${d.year}',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),

              // ✅ ON/OFF balanceo mercado
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Balanceo por mercado (suave)'),
                subtitle:
                    const Text('Ajusta el objetivo 0.90x–1.10x según 1M.'),
                value: _marketBalanceEnabled,
                onChanged: (v) => _setMarketBalanceEnabled(v),
              ),

              const SizedBox(height: 6),
              Text(
                _marketBalanceEnabled
                    ? 'Mercado (media 1M): $marketText  →  Factor aplicado: $multText'
                    : 'Mercado (media 1M): $marketText  →  Balanceo OFF (solo informativo)',
                style:
                    theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),

              const SizedBox(height: 10),
              Text(
                _completed
                    ? '✅ Mes completado. Disciplina mantiene el rumbo.'
                    : '🎯 Queda por invertir este mes: $remainingText',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatChip(
                      label: 'Objetivo del mes',
                      value: '${d.monthlyTargetEur.toStringAsFixed(2)}€',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatChip(
                      label: 'Invertido',
                      value: '${d.investedThisMonthEur.toStringAsFixed(2)}€',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Base plan: ${d.baseMonthlyTargetEur.toStringAsFixed(2)}€',
                style:
                    theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Marcar mes como completado'),
                subtitle: const Text(
                    'Guarda el estado para que Disciplina no insista.'),
                value: _completed,
                onChanged: (v) => _toggleCompleted(v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recomendación',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              if (_plan == null)
                const Text('Crea tu Plan para recibir recomendaciones.'),
              if (_plan != null && _completed)
                const Text(
                    'Este mes ya está completado. Si aportas extra, reparte según pesos objetivo.'),
              if (_plan != null && !_completed && d.suggestions.isEmpty)
                const Text('Sin recomendaciones claras. Mantén tu plan.'),
              if (_plan != null && !_completed && d.suggestions.isNotEmpty) ...[
                ...d.suggestions.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SuggestionRow(
                        ticker: s.ticker,
                        amount: s.amountEur,
                        reason: s.reason,
                        onTapRegister: () =>
                            _openRegister(s.ticker, s.amountEur),
                      ),
                    )),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          child: Text(
            'Movimientos: ${_movements.length}  ·  Quotes(1M): ${_quotes.length}',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  String _monthNameEs(int m) {
    const names = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre'
    ];
    if (m < 1 || m > 12) return 'Mes';
    return names[m - 1];
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 44),
            const SizedBox(height: 10),
            Text('Error:\n$error', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0x0FFFFFFF),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: child,
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0x0FFFFFFF),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  final String ticker;
  final double amount;
  final String reason;
  final VoidCallback onTapRegister;

  const _SuggestionRow({
    required this.ticker,
    required this.amount,
    required this.reason,
    required this.onTapRegister,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTapRegister,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: const Color(0x0DFFFFFF),
          border: Border.all(color: const Color(0x1AFFFFFF)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: const Color(0x14FFFFFF),
              ),
              child: Text(
                ticker.isEmpty
                    ? '?'
                    : ticker.substring(0, _min(4, ticker.length)),
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticker.isEmpty ? 'Ticker' : ticker,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    reason,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${amount.toStringAsFixed(2)}€',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  int _min(int a, int b) => a < b ? a : b;
}
