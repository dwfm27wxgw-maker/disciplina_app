import 'package:shared_preferences/shared_preferences.dart';

class CoachStore {
  static const String _keyCompletedPrefix =
      'coach_month_completed_v1:'; // + YYYY-MM

  static String _keyFor(String monthKey) => '$_keyCompletedPrefix$monthKey';

  static Future<bool> isMonthCompleted(String monthKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyFor(monthKey)) ?? false;
  }

  static Future<void> setMonthCompleted(String monthKey, bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFor(monthKey), completed);
  }
}
