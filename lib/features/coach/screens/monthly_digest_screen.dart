import 'package:flutter/material.dart';

import '../../../core/services/notification_service.dart';

class MonthlyDigestScreen extends StatefulWidget {
  const MonthlyDigestScreen({super.key});

  @override
  State<MonthlyDigestScreen> createState() => _MonthlyDigestScreenState();
}

class _MonthlyDigestScreenState extends State<MonthlyDigestScreen> {
  bool _monthDone = false;
  String _status = 'Modo seguro: Android compila.';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final headline =
        _monthDone ? 'Mes completado ✅' : 'Coach mensual · Disciplina';

    final message = _monthDone
        ? 'Perfecto. Este mes ya está hecho. Mantén la disciplina y el próximo mes volvemos a ajustar.'
        : 'Este mes: prioriza el ETF con más desviación de tu objetivo.\n\n'
            '⚠️ Nota: ahora mismo esta pantalla es “modo seguro” para que Android compile.\n'
            'En el siguiente paso conectamos el cálculo real desde tus movimientos y tu Plan.';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Coach mensual'),
        actions: [
          IconButton(
            tooltip: _monthDone
                ? 'Marcar como NO completado'
                : 'Marcar como completado',
            onPressed: () => setState(() => _monthDone = !_monthDone),
            icon: Icon(_monthDone ? Icons.undo : Icons.check_circle_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            headline,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                message,
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.info_outline),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _status,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // BOTONES
          FilledButton.icon(
            onPressed: () async {
              try {
                await NotificationService.showTestNow();
                if (!mounted) return;
                setState(() {
                  _status =
                      '✅ Notificación enviada. Si NO suena: revisa canal/ajustes de notificación en OPPO.';
                });
              } catch (e) {
                if (!mounted) return;
                setState(() => _status = '❌ Error enviando notificación: $e');
              }
            },
            icon: const Icon(Icons.notifications_active),
            label: const Text('Probar sonido ahora'),
          ),
          const SizedBox(height: 10),
          FilledButton.tonalIcon(
            onPressed: () async {
              try {
                await NotificationService.rescheduleNextMonthCoach();
                if (!mounted) return;
                setState(() =>
                    _status = '✅ Programado próximo mes (día 1 a las 10:00).');
              } catch (e) {
                if (!mounted) return;
                setState(() => _status = '❌ Error programando: $e');
              }
            },
            icon: const Icon(Icons.schedule),
            label: const Text('Programar próximo mes'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              try {
                await NotificationService.cancelMonthlyCoach();
                if (!mounted) return;
                setState(() => _status = '🧹 Coach mensual cancelado.');
              } catch (e) {
                if (!mounted) return;
                setState(() => _status = '❌ Error cancelando: $e');
              }
            },
            icon: const Icon(Icons.cancel),
            label: const Text('Cancelar notificación'),
          ),

          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Volver'),
          ),
        ],
      ),
    );
  }
}
