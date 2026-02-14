import 'package:flutter/material.dart';

import 'package:disciplina_app/core/app/app_bus.dart';

import 'package:disciplina_app/features/home/screens/home_page.dart';
import 'package:disciplina_app/features/movements/screens/movements_page.dart';
import 'package:disciplina_app/features/bot/screens/plan_page.dart';
import 'package:disciplina_app/features/bot/screens/bot_page.dart';
import 'package:disciplina_app/features/home/screens/add_movement_screen.dart';

class DisciplinaShell extends StatefulWidget {
  const DisciplinaShell({super.key});

  @override
  State<DisciplinaShell> createState() => _DisciplinaShellState();
}

class _DisciplinaShellState extends State<DisciplinaShell> {
  int _index = 0;

  // ✅ Keys para poder “decirle” a cada tab que recargue sin recrearla
  final GlobalKey _homeKey = GlobalKey();
  final GlobalKey _movsKey = GlobalKey();
  final GlobalKey _planKey = GlobalKey();
  final GlobalKey _botKey = GlobalKey();

  late final VoidCallback _busListener;

  @override
  void initState() {
    super.initState();

    _busListener = () {
      // Cuando cambia algo, pide recarga a las pantallas.
      _softRefreshAllTabs();
    };

    AppBus.changes.addListener(_busListener);
  }

  @override
  void dispose() {
    AppBus.changes.removeListener(_busListener);
    super.dispose();
  }

  void _softRefreshAllTabs() {
    // HomePage tiene _reloadAll()
    try {
      final s = _homeKey.currentState as dynamic;
      s?._reloadAll();
    } catch (_) {}

    // MovementsPage tiene _reload()
    try {
      final s = _movsKey.currentState as dynamic;
      s?._reload();
    } catch (_) {}

    // PlanPage/BotPage de momento son simples; si luego les metes reload, aquí se llama.
    // (No pasa nada si no existe el método.)
    try {
      final s = _planKey.currentState as dynamic;
      s?._reload();
    } catch (_) {}

    try {
      final s = _botKey.currentState as dynamic;
      s?._reload();
    } catch (_) {}
  }

  Future<void> _openAddMovement() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddMovementScreen()),
    );

    // ✅ Fallback: por si algún flujo no llama AppBus.bump()
    AppBus.bump();
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF0B0F14);

    return Scaffold(
      backgroundColor: bg,
      body: IndexedStack(
        index: _index,
        children: [
          HomePage(key: _homeKey),
          MovementsPage(key: _movsKey),
          PlanPage(key: _planKey),
          BotPage(key: _botKey),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddMovement,
        backgroundColor: const Color(0xFFFFD60A),
        foregroundColor: const Color(0xFF0B0F14),
        child: const Icon(Icons.add_rounded),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: bg,
        selectedItemColor: const Color(0xFFFFD60A),
        unselectedItemColor: const Color(0xFF9AA6B2),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart_rounded),
            label: 'Portfolio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_rounded),
            label: 'Movs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.tune_rounded),
            label: 'Plan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy_rounded),
            label: 'Bot',
          ),
        ],
      ),
    );
  }
}
