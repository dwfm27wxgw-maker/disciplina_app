// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';

import 'package:disciplina_app/core/ui/d_widgets.dart';
import 'package:disciplina_app/core/ui/app_theme.dart';
import 'package:disciplina_app/features/plan/screens/edit_plan_screen.dart';

class PlanPage extends StatelessWidget {
  const PlanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Plan'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const DCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DTitle('Centro de Disciplina'),
                SizedBox(height: 8),
                DMuted(
                  'Edita tu aportación mensual y los pesos objetivo. '
                  'La recomendación del mes se calcula a partir de este plan.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          DCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    DTitle('Acciones'),
                    Spacer(),
                    DPill('MVP'),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const EditPlanScreen()),
                    );
                  },
                  icon: const Icon(Icons.tune_rounded),
                  label: const Text('Editar plan'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
