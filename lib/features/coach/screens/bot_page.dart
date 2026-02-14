import 'package:flutter/material.dart';

class BotPage extends StatelessWidget {
  const BotPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bot (pendiente)')),
      body: const Center(child: Text('Pantalla pendiente.')),
    );
  }
}
