import 'package:flutter/material.dart';

class ReviewUnknownScreen extends StatelessWidget {
  const ReviewUnknownScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Revisar (pendiente)')),
      body: const Center(child: Text('Pantalla pendiente.')),
    );
  }
}
