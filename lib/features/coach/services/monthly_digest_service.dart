import 'package:flutter/material.dart';

import '../../../core/models/movement.dart';
import '../../../core/storage/local_store.dart';

class AddMovementScreen extends StatefulWidget {
  const AddMovementScreen({super.key, this.presetTicker, this.presetAmount});

  final String? presetTicker;
  final double? presetAmount;

  @override
  State<AddMovementScreen> createState() => _AddMovementScreenState();
}

class _AddMovementScreenState extends State<AddMovementScreen> {
  final _tickerCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tickerCtrl.text = (widget.presetTicker ?? '').toUpperCase().trim();
    if (widget.presetAmount != null && widget.presetAmount! > 0) {
      _amountCtrl.text = widget.presetAmount!.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _tickerCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final ticker = _tickerCtrl.text.toUpperCase().trim();
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.').trim());

    if (ticker.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Revisa ticker e importe')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final m = Movement(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        ticker: ticker,
        amount: amount,
        date: _date,
      );

      await LocalStore.saveMovement(m);

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1013),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E1013),
        elevation: 0,
        title: const Text('Registrar compra'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _tickerCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Ticker',
                hintText: 'Ej: IWDA',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Importe (€)',
                hintText: 'Ej: 50',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Fecha: ${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}',
                    style: TextStyle(color: Colors.white.withOpacity(0.85)),
                  ),
                ),
                TextButton(
                  onPressed: _pickDate,
                  child: const Text('Cambiar'),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Guardando…' : 'Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}