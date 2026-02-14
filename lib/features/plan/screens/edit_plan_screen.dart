import 'package:flutter/material.dart';

import '../../../core/models/plan.dart';
import '../../../core/storage/local_store.dart';

class EditPlanScreen extends StatefulWidget {
  const EditPlanScreen({super.key});

  @override
  State<EditPlanScreen> createState() => _EditPlanScreenState();
}

class _EditPlanScreenState extends State<EditPlanScreen> {
  final _monthly = TextEditingController(text: '50');
  final _t1 = TextEditingController(text: 'IWLE');
  final _w1 = TextEditingController(text: '0.60');
  final _t2 = TextEditingController(text: 'EIMI');
  final _w2 = TextEditingController(text: '0.10');
  final _t3 = TextEditingController(text: 'AGGH');
  final _w3 = TextEditingController(text: '0.30');

  @override
  void dispose() {
    _monthly.dispose();
    _t1.dispose();
    _w1.dispose();
    _t2.dispose();
    _w2.dispose();
    _t3.dispose();
    _w3.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final p = await LocalStore.getPlan();
    if (p == null) return;

    _monthly.text = p.monthlyContribution.toStringAsFixed(0);

    final keys = p.targetWeights.keys.toList();
    final vals = p.targetWeights.values.toList();

    if (keys.isNotEmpty) {
      _t1.text = keys[0];
      _w1.text = vals[0].toStringAsFixed(2);
    }
    if (keys.length > 1) {
      _t2.text = keys[1];
      _w2.text = vals[1].toStringAsFixed(2);
    }
    if (keys.length > 2) {
      _t3.text = keys[2];
      _w3.text = vals[2].toStringAsFixed(2);
    }

    setState(() {});
  }

  Future<void> _save() async {
    final mc = double.tryParse(_monthly.text.replaceAll(',', '.')) ?? 50.0;

    final Map<String, double> w = {};
    void put(String t, String ww) {
      final tt = t.trim().toUpperCase();
      final vv = double.tryParse(ww.replaceAll(',', '.')) ?? 0.0;
      if (tt.isNotEmpty && vv > 0) w[tt] = vv;
    }

    put(_t1.text, _w1.text);
    put(_t2.text, _w2.text);
    put(_t3.text, _w3.text);

    final sum = w.values.fold<double>(0, (a, b) => a + b);
    if (sum <= 0.0001) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pon al menos un ticker con peso.')),
      );
      return;
    }

    final norm = <String, double>{};
    for (final e in w.entries) {
      norm[e.key] = e.value / sum;
    }

    await LocalStore.savePlan(
      Plan(monthlyContribution: mc, targetWeights: norm),
    );

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan'),
        actions: [
          IconButton(onPressed: _save, icon: const Icon(Icons.check)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _monthly,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Aportación mensual (€)',
            ),
          ),
          const SizedBox(height: 14),
          _row('Ticker 1', _t1, 'Peso 1', _w1),
          const SizedBox(height: 10),
          _row('Ticker 2', _t2, 'Peso 2', _w2),
          const SizedBox(height: 10),
          _row('Ticker 3', _t3, 'Peso 3', _w3),
          const SizedBox(height: 16),
          const Text('Tip: los pesos se normalizan para sumar 1.0.'),
        ],
      ),
    );
  }

  Widget _row(
    String l1,
    TextEditingController c1,
    String l2,
    TextEditingController c2,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            controller: c1,
            decoration: InputDecoration(labelText: l1),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: TextField(
            controller: c2,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: l2),
          ),
        ),
      ],
    );
  }
}
