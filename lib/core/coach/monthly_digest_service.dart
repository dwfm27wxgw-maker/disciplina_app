// lib/features/coach/screens/monthly_digest_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/notification_service.dart';
import '../../../core/storage/local_store.dart';
import '../../../core/models/plan.dart';
import '../../../core/models/movement.dart';

class MonthlyDigestScreen extends StatefulWidget {
  const MonthlyDigestScreen({super.key});

  @override
  State<MonthlyDigestScreen> createState() => _MonthlyDigestScreenState();
}

class _MonthlyDigestScreenState extends State<MonthlyDigestScreen> {
  bool _loading = true;
  String _message = '';
  String _title = 'Disciplina';
  Map<String, double> _buyEuros = {}; // ticker -> euros recomendados
  String _status = 'Cargando…';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _status = 'Cargando…';
    });

    try {
      // --- 1) Cargar movimientos y plan de forma tolerante ---
      final movements = await _safeGetMovements();
      final plan = await _safeGetPlan();

      // --- 2) Calcular recomendación en € para ESTE mes ---
      final result = _buildMonthlyDigest(movements: movements, plan: plan);

      setState(() {
        _title = result.title;
        _message = result.message;
        _buyEuros = result.buyEuros;
        _status = result.status;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _title = 'Disciplina';
        _message = 'No se pudo generar el coach mensual.\n\nDetalle: $e';
        _buyEuros = {};
        _status = 'Error';
        _loading = false;
      });
    }
  }

  // -----------------------------
  // UI
  // -----------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coach mensual'),
        actions: [
          IconButton(
            tooltip: 'Recargar',
            onPressed: _loading ? null : _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const _LoadingBody()
          : RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeaderCard(),
                  const SizedBox(height: 12),
                  _buildMessageCard(),
                  const SizedBox(height: 12),
                  if (_buyEuros.isNotEmpty) _buildBuyListCard(),
                  if (_buyEuros.isNotEmpty) const SizedBox(height: 12),
                  _buildActionsCard(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _status,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mensaje del mes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            SelectableText(
              _message.isEmpty ? '—' : _message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuyListCard() {
    final entries = _buyEuros.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recomendación en € (Top)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            ...entries.take(5).map((e) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        e.key,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      '${e.value.toStringAsFixed(2)} €',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Acciones',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),

            // Enviar aviso
            ElevatedButton.icon(
              onPressed: _message.trim().isEmpty
                  ? null
                  : () async {
                      final msg = _message.trim();
                      try {
                        await NotificationService.showMonthlyCoachNow(
                          title: 'Disciplina — Coach mensual',
                          body: msg,
                        );

                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('✅ Coach lanzado (en Windows es demo)'),
                          ),
                        );
                      } catch (_) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('ℹ️ Notificaciones solo en Android/iOS'),
                          ),
                        );
                      }
                    },
              icon: const Icon(Icons.notifications_active),
              label: const Text('Enviar aviso (test)'),
            ),

            const SizedBox(height: 10),

            // Programar (stub en Windows)
            OutlinedButton.icon(
              onPressed: _message.trim().isEmpty
                  ? null
                  : () async {
                      final msg = _message.trim();
                      try {
                        await NotificationService.scheduleNextMonthCoach(
                          title: 'Disciplina — Coach mensual',
                          body: msg,
                        );

                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('📅 Programación enviada (Windows: demo)'),
                          ),
                        );
                      } catch (_) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('ℹ️ Programación solo en Android/iOS'),
                          ),
                        );
                      }
                    },
              icon: const Icon(Icons.schedule),
              label: const Text('Programar próximo mes'),
            ),

            const SizedBox(height: 10),

            // Copiar
            TextButton.icon(
              onPressed: _message.trim().isEmpty
                  ? null
                  : () async {
                      await Clipboard.setData(ClipboardData(text: _message));
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('📋 Mensaje copiado')),
                      );
                    },
              icon: const Icon(Icons.copy),
              label: const Text('Copiar mensaje'),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------
  // Generación del digest (tolerante)
  // -----------------------------

  Future<List<dynamic>> _safeGetMovements() async {
    try {
      final res = await (LocalStore as dynamic).getMovements();
      if (res is List) return res.cast<dynamic>();
      return <dynamic>[];
    } catch (_) {
      // Algunas versiones lo llaman distinto
      try {
        final res = await (LocalStore as dynamic).loadMovements();
        if (res is List) return res.cast<dynamic>();
      } catch (_) {}
      return <dynamic>[];
    }
  }

  Future<dynamic> _safeGetPlan() async {
    try {
      return await (LocalStore as dynamic).getPlan();
    } catch (_) {
      try {
        return await (LocalStore as dynamic).loadPlan();
      } catch (_) {}
      return null;
    }
  }

  _DigestResult _buildMonthlyDigest({
    required List<dynamic> movements,
    required dynamic plan,
  }) {
    final now = DateTime.now();
    final y = now.year;
    final m = now.month;

    // 1) Pesos del plan (tolerante)
    final weights = _extractWeights(plan);

    // 2) Presupuesto mensual (tolerante)
    final budget = _extractMonthlyBudget(plan, fallback: 50.0);

    // Si no hay pesos, no podemos recomendar bien
    if (weights.isEmpty) {
      final msg = 'No hay Plan configurado.\n\n'
          'Ve a “Plan” y define pesos objetivo por ETF para que pueda recomendar.';
      return _DigestResult(
        title: 'Coach mensual',
        status: 'Sin Plan (pesos objetivo)',
        message: msg,
        buyEuros: const {},
      );
    }

    // 3) Invertido este mes por ticker
    final investedThisMonth = <String, double>{};
    double totalMonth = 0;

    for (final mv in movements) {
      final dt = _getDate(mv);
      if (dt == null) continue;
      if (dt.year != y || dt.month != m) continue;

      final t = _getTicker(mv);
      final amount = _getAmount(mv);

      if (t.isEmpty) continue;
      if (amount <= 0) continue;

      investedThisMonth[t] = (investedThisMonth[t] ?? 0) + amount;
      totalMonth += amount;
    }

    // 4) Objetivo vs actual => diff (solo positivos = falta aportar)
    final buy = <String, double>{};
    for (final entry in weights.entries) {
      final ticker = entry.key;
      final w = entry.value;

      final target = budget * w;
      final actual = investedThisMonth[ticker] ?? 0.0;
      final diff = target - actual;

      if (diff > 0.01) {
        buy[ticker] = diff;
      }
    }

    // 5) Mensaje
    final remaining = (budget - totalMonth);
    final remainingStr = remaining.toStringAsFixed(2);

    String header = 'Mes ${_monthName(m)} $y\n'
        'Presupuesto: ${budget.toStringAsFixed(2)} €\n'
        'Invertido: ${totalMonth.toStringAsFixed(2)} €\n'
        'Restante: $remainingStr €\n\n';

    if (buy.isEmpty) {
      final msg = header +
          '✅ Mes completado según tu Plan.\n'
              'Mantén el rumbo: disciplina hoy, libertad mañana.';
      return _DigestResult(
        title: 'Coach mensual',
        status: 'Mes completado',
        message: msg,
        buyEuros: const {},
      );
    }

    final top = buy.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final lines = top.take(3).map((e) {
      return '• ${e.key}: +${e.value.toStringAsFixed(2)} €';
    }).join('\n');

    final msg = header +
        '📌 Recomendación (prioridad):\n'
            '$lines\n\n'
            'Regla: no es trading. Solo ajustamos el reparto para acercarnos al Plan.';

    return _DigestResult(
      title: 'Coach mensual',
      status: 'Recomendación lista',
      message: msg,
      buyEuros: buy,
    );
  }

  Map<String, double> _extractWeights(dynamic plan) {
    if (plan == null) return {};

    // Si es Plan real
    try {
      final w = (plan as dynamic).targetWeights;
      if (w is Map) {
        return w.map((k, v) => MapEntry('$k', _toDouble(v)));
      }
    } catch (_) {}

    // Alternativas de nombre
    try {
      final w = (plan as dynamic).weights;
      if (w is Map) {
        return w.map((k, v) => MapEntry('$k', _toDouble(v)));
      }
    } catch (_) {}

    // Si viene como Map
    if (plan is Map) {
      final w = plan['targetWeights'] ?? plan['weights'];
      if (w is Map) {
        return w.map((k, v) => MapEntry('$k', _toDouble(v)));
      }
    }

    return {};
  }

  double _extractMonthlyBudget(dynamic plan, {required double fallback}) {
    if (plan == null) return fallback;

    // Plan real
    for (final key in [
      'monthlyContribution',
      'monthlyBudget',
      'monthlyAmount'
    ]) {
      try {
        final v = (plan as dynamic).__getattr__(key);
        // ignore: unused_local_variable
        if (v != null) {}
      } catch (_) {}
    }

    try {
      final v = (plan as dynamic).monthlyContribution;
      final d = _toDouble(v);
      if (d > 0) return d;
    } catch (_) {}

    try {
      final v = (plan as dynamic).monthlyBudget;
      final d = _toDouble(v);
      if (d > 0) return d;
    } catch (_) {}

    // Map
    if (plan is Map) {
      final v = plan['monthlyContribution'] ??
          plan['monthlyBudget'] ??
          plan['monthlyAmount'];
      final d = _toDouble(v);
      if (d > 0) return d;
    }

    return fallback;
  }

  // -----------------------------
  // Helpers tolerantes (Map/obj)
  // -----------------------------
  String _getTicker(dynamic mv) {
    try {
      final t = (mv as dynamic).ticker;
      if (t != null) return '$t';
    } catch (_) {}
    try {
      final t = (mv as dynamic).symbol;
      if (t != null) return '$t';
    } catch (_) {}
    if (mv is Map) {
      final t = mv['ticker'] ?? mv['symbol'] ?? mv['etf'] ?? mv['asset'];
      if (t != null) return '$t';
    }
    return 'UNKNOWN';
  }

  double _getAmount(dynamic mv) {
    try {
      final a = (mv as dynamic).amount;
      return _toDouble(a);
    } catch (_) {}
    try {
      final a = (mv as dynamic).value;
      return _toDouble(a);
    } catch (_) {}
    if (mv is Map) {
      final a = mv['amount'] ?? mv['value'] ?? mv['importe'];
      return _toDouble(a);
    }
    return 0.0;
  }

  DateTime? _getDate(dynamic mv) {
    try {
      final d = (mv as dynamic).date;
      if (d is DateTime) return d;
      if (d != null) return DateTime.tryParse('$d');
    } catch (_) {}
    if (mv is Map) {
      final d = mv['date'] ?? mv['createdAt'] ?? mv['timestamp'];
      if (d is DateTime) return d;
      if (d is int) {
        // epoch ms o s
        if (d > 1000000000000) return DateTime.fromMillisecondsSinceEpoch(d);
        return DateTime.fromMillisecondsSinceEpoch(d * 1000);
      }
      if (d != null) return DateTime.tryParse('$d');
    }
    return null;
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    final s = '$v'.replaceAll(',', '.');
    return double.tryParse(s) ?? 0.0;
  }

  String _monthName(int m) {
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    if (m < 1 || m > 12) return '';
    return months[m - 1];
  }
}

class _DigestResult {
  final String title;
  final String status;
  final String message;
  final Map<String, double> buyEuros;

  _DigestResult({
    required this.title,
    required this.status,
    required this.message,
    required this.buyEuros,
  });
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Generando coach mensual…'),
          ],
        ),
      ),
    );
  }
}
