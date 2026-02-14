import 'package:flutter/material.dart';

import '../../../core/models/movement.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/storage/local_store.dart';

class AddMovementScreen extends StatefulWidget {
  final String? presetTicker;
  final double? presetAmount;

  const AddMovementScreen({
    super.key,
    this.presetTicker,
    this.presetAmount,
  });

  @override
  State<AddMovementScreen> createState() => _AddMovementScreenState();
}

class _AddMovementScreenState extends State<AddMovementScreen> {
  final _ticker = TextEditingController();
  final _amount = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.presetTicker != null) _ticker.text = widget.presetTicker!;
    if (widget.presetAmount != null) {
      _amount.text = widget.presetAmount!.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _date,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final t = _ticker.text.trim().toUpperCase();
    final a = double.tryParse(_amount.text.replaceAll(',', '.')) ?? 0.0;

    if (t.isEmpty || a <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa ticker e importe válido.')),
      );
      return;
    }

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final m = Movement(
      id: id,
      ticker: t,
      amount: a,
      date: _date,
    );

    await LocalStore.saveMovement(m);

    // ✅ Recalcula el coach mensual
    await NotificationService.rescheduleNextMonthCoach();

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar compra')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _ticker,
              decoration: const InputDecoration(labelText: 'Ticker (ej. IWLE)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Importe (€)'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Fecha: ${_date.day.toString().padLeft(2, '0')}/'
                    '${_date.month.toString().padLeft(2, '0')}/${_date.year}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Cambiar'),
                ),
              ],
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
