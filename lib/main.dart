import 'package:flutter/material.dart';

import 'core/services/notification_service.dart';
import 'features/home/screens/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await NotificationService.init();
  } catch (e) {
    // Nunca romper arranque
    // ignore: avoid_print
    print('Notification init failed: $e');
  }

  runApp(const DisciplinaApp());
}

class DisciplinaApp extends StatelessWidget {
  const DisciplinaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const HomePage(),
    );
  }
}
