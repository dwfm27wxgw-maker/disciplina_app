import 'package:shared_preferences/shared_preferences.dart';

class LocalStoreMonthly {
  static const String _marketBalanceEnabledKey = 'market_balance_enabled_v1';

  static String _seenKey(int year, int month) => 'month_seen_v1_${year}_$month';
  static String _completedKey(int year, int month) =>
      'month_completed_v1_${year}_$month';

  /// ✅ Por defecto: ON
  static Future<bool> getMarketBalanceEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_marketBalanceEnabledKey) ?? true;
  }

  static Future<void> setMarketBalanceEnabled(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_marketBalanceEnabledKey, v);
  }

  static Future<void> setMonthSeen(int year, int month) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenKey(year, month), true);
  }

  static Future<bool> isMonthCompleted(int year, int month) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_completedKey(year, month)) ?? false;
  }

  static Future<void> setMonthCompleted(int year, int month, bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedKey(year, month), v);
  }
}
