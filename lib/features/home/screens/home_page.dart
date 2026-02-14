import 'package:flutter/material.dart';

import '../../../core/models/market_quote.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/storage/local_store.dart';
import '../../coach/screens/monthly_digest_screen.dart';
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

  List<dynamic> _movements = const [];
  List<MarketQuote> _quotes = const [];

  final List<String> _tickers = const ['IWLE', 'EIMI', 'AGGH'];

  @override
  void initState() {
    super.initState();
    _reloadAll();
  }

  Future<void> _reloadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final movements = await LocalStore.getMovements();
      final quotes = await MarketService.fetchQuotes(_tickers);

      if (!mounted) return;
      setState(() {
        _movements = movements;
        _quotes = quotes;
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

  Future<void> _openAdd({String? presetTicker, double? presetAmount}) async {
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

  Future<void> _openPlan() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EditPlanScreen()),
    );
    await _reloadAll();
  }

  Future<void> _openMonthlyDigest() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MonthlyDigestScreen()),
    );
    await _reloadAll();
  }

  Future<void> _testCoachNow() async {
    try {
      await NotificationService.testCoachNow();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Test coach enviado (notificación).')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ No se pudo enviar el test: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Disciplina'),
        actions: [
          IconButton(
            tooltip: 'Mensaje del mes',
            onPressed: _openMonthlyDigest,
            icon: const Icon(Icons.message_outlined),
          ),
          IconButton(
            tooltip: 'Plan',
            onPressed: _openPlan,
            icon: const Icon(Icons.tune),
          ),
          IconButton(
            tooltip: 'Test coach',
            onPressed: _testCoachNow,
            icon: const Icon(Icons.notifications_active_outlined),
          ),
          IconButton(
            tooltip: 'Recargar',
            onPressed: _reloadAll,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAdd(),
        icon: const Icon(Icons.add),
        label: const Text('Registrar'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null)
              ? _ErrorView(error: _error!, onRetry: _reloadAll)
              : _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Card(
          child: Row(
            children: [
              const Icon(Icons.auto_awesome),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Coach mensual',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              TextButton(
                onPressed: _testCoachNow,
                child: const Text('Test coach'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        _Card(
          child: Row(
            children: [
              const Icon(Icons.savings_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Movimientos: ${_movements.length}',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              TextButton(
                onPressed: _openMonthlyDigest,
                child: const Text('Mensaje del mes'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Mercado (mock)
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mercado hoy (mock)',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              if (_quotes.isEmpty)
                Text(
                  'Sin datos. Pulsa recargar.',
                  style: theme.textTheme.bodyMedium,
                ),
              if (_quotes.isNotEmpty)
                ..._quotes.map(
                  (q) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            q.ticker,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Text(
                          '${q.price.toStringAsFixed(2)}€',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: q.changePercent >= 0
                                ? const Color(0x1434C759)
                                : const Color(0x14FF3B30),
                            border: Border.all(
                              color: q.changePercent >= 0
                                  ? const Color(0x3334C759)
                                  : const Color(0x33FF3B30),
                            ),
                          ),
                          child: Text(
                            '${q.changePercent.toStringAsFixed(2)}%',
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: q.changePercent >= 0
                                  ? const Color(0xFF34C759)
                                  : const Color(0xFFFF3B30),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Registrar compra',
                          onPressed: () => _openAdd(
                            presetTicker: q.ticker,
                            presetAmount: 0,
                          ),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Últimas compras
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Últimas compras',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              if (_movements.isEmpty)
                Text(
                  'Aún no hay compras registradas.',
                  style: theme.textTheme.bodyMedium,
                ),
              if (_movements.isNotEmpty)
                ..._movements.reversed.take(10).map((m) {
                  final mm = LocalStore.tryParseMovement(m);

                  final ticker =
                      (mm?.ticker ?? (m is Map ? (m['ticker'] ?? '?') : '?'))
                          .toString();

                  final amount = (mm?.amount ??
                          (m is Map
                              ? double.tryParse(
                                      (m['amount'] ?? '0').toString()) ??
                                  0.0
                              : 0.0))
                      .toDouble();

                  final date = (mm?.date);
                  final dateText = (date == null)
                      ? ''
                      : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            ticker.isEmpty ? '?' : ticker,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Text(
                          dateText,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${amount.toStringAsFixed(2)}€',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),

        const SizedBox(height: 90),
      ],
    );
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
