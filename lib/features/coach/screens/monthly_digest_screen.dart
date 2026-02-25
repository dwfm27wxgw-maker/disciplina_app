import 'package:flutter/material.dart';

import '../../../core/services/notification_service.dart';
import '../services/monthly_digest_service.dart';

class MonthlyDigestScreen extends StatefulWidget {
  const MonthlyDigestScreen({super.key});

  @override
  State<MonthlyDigestScreen> createState() => _MonthlyDigestScreenState();
}

class _MonthlyDigestScreenState extends State<MonthlyDigestScreen> {
  MonthlyDigest? _digest;
  bool _loading = true;
  bool _scheduling = false;
  DateTime? _nextCoachAt;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);

    try {
      final d = await MonthlyDigestService.buildMonthlyDigest();
      final nextDt = await NotificationService.getNextScheduledCoachAt();

      if (!mounted) return;
      setState(() {
        _digest = d;
        _nextCoachAt = nextDt;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _digest = null;
        _loading = false;
      });
    }
  }

  String _fmt(DateTime? dt) {
    if (dt == null) return '(sin programar aún)';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final digest = _digest;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coach mensual'),
        actions: [
          IconButton(
            tooltip: 'Recargar',
            onPressed: _loadAll,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _card(
                  title: digest?.headline ?? 'Disciplina',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        digest?.actionLine ?? 'Acción: revisa tu plan del mes.',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        digest?.fullBody ??
                            'No hay mensaje disponible. Registra compras para que el coach sea más preciso.',
                        style: const TextStyle(fontSize: 14, height: 1.35),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _card(
                  title: 'Notificación programada',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Próxima notificación: ${_fmt(_nextCoachAt)}',
                        style: const TextStyle(fontSize: 14, height: 1.35),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                await NotificationService.showMonthlyCoachNow(
                                  title: 'Coach mensual',
                                  body:
                                      'Disciplina: notificación de prueba (Ahora).',
                                );
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Notificación enviada.'),
                                  ),
                                );
                              },
                              child: const Text('Probar ahora'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _scheduling
                                  ? null
                                  : () async {
                                      setState(() => _scheduling = true);

                                      final dt = await NotificationService
                                          .scheduleNextMonthCoachAndReturnDate(
                                        hour: 9,
                                        minute: 0,
                                      );

                                      if (!mounted) return;
                                      setState(() {
                                        _scheduling = false;
                                        if (dt != null) _nextCoachAt = dt;
                                      });

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(dt == null
                                              ? 'No se pudo reprogramar.'
                                              : 'Programada: ${_fmt(dt)}'),
                                        ),
                                      );
                                    },
                              child: Text(
                                _scheduling
                                    ? 'Reprogramando…'
                                    : 'Reprogramar próximo mes',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Se programa el 1 del mes siguiente a las 09:00 (hora local).',
                        style: TextStyle(fontSize: 12, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}