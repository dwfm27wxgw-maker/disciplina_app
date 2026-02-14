import 'package:flutter/material.dart';

import 'core/notifications/notification_service.dart';
import 'features/home/screens/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ No rompemos build si algo del plugin falla en Windows
  try {
    await NotificationService.init();
    await NotificationService.rescheduleNextMonthCoach();
  } catch (_) {}

  runApp(const DisciplinaApp());
}

class DisciplinaApp extends StatelessWidget {
  const DisciplinaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Disciplina',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0F14),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4CAF7A),
          secondary: Color(0xFF1F3A5F),
        ),
      ),
      home: const HomePage(),
    );
  }
}
