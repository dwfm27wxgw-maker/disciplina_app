import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/movement.dart';
import '../models/plan.dart';

class LocalStore {
  static const _kMovements = 'movements_v1';
  static const _kPlan = 'plan_v1';
  static const _kTickers = 'tickers_v1';
  static const _kMonthDonePrefix = 'month_done_v1_';

  // ---- Movements ----
  static Future<List<Movement>> getMovements() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getStringList(_kMovements) ?? <String>[];
    final out = <Movement>[];
    for (final s in raw) {
      try {
        final map = jsonDecode(s) as Map<String, dynamic>;
        out.add(Movement.fromJson(map));
      } catch (_) {}
    }
    // newest first
    out.sort((a, b) => b.date.compareTo(a.date));
    return out;
  }

  static Future<void> saveMovement(Movement m) async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(_kMovements) ?? <String>[];
    list.add(jsonEncode(m.toJson()));
    await p.setStringList(_kMovements, list);
  }

  static Future<void> saveMovementsBulk(List<Movement> movements) async {
    final p = await SharedPreferences.getInstance();
    final list = movements.map((m) => jsonEncode(m.toJson())).toList();
    await p.setStringList(_kMovements, list);
  }

  static Future<void> deleteMovementById(String id) async {
    final all = await getMovements();
    final next = all.where((m) => m.id != id).toList();
    await saveMovementsBulk(next);
  }

  // ---- Plan ----
  static Future<Plan?> getPlan() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_kPlan);
    if (s == null || s.isEmpty) return null;
    try {
      final map = jsonDecode(s) as Map<String, dynamic>;
      return Plan.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  static Future<void> savePlan(Plan plan) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kPlan, jsonEncode(plan.toJson()));
  }

  // ---- Tickers ----
  static Future<List<String>> getTickers() async {
    final p = await SharedPreferences.getInstance();
    final t = p.getStringList(_kTickers);
    if (t != null && t.isNotEmpty) return t;
    // default
    return <String>['IWLE', 'EUNU', 'IS3N'];
  }

  static Future<void> saveTickers(List<String> tickers) async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_kTickers, tickers);
  }

  // ---- Month done ----
  static String _monthDoneKey(int year, int month) => '$_kMonthDonePrefix$year-$month';

  static Future<bool> getMonthDone({required int year, required int month}) async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_monthDoneKey(year, month)) ?? false;
  }

  static Future<void> setMonthDone(bool val, {required int year, required int month}) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_monthDoneKey(year, month), val);
  }
}