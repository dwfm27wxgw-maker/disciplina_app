import 'package:flutter/material.dart';

class BotDisciplinaScreen extends StatelessWidget {
  final String ahorroMensual;
  final String anos;
  final String riesgo;

  const BotDisciplinaScreen({
    super.key,
    required this.ahorroMensual,
    required this.anos,
    required this.riesgo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bot Disciplina')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ahorro mensual: €$ahorroMensual',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 12),
            Text('Años: $anos', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Text('Riesgo: $riesgo', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 32),
            const Text(
              'Este será tu plan Disciplina personalizado.\n\n'
              'Aquí construiremos tu estrategia de inversión paso a paso.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
