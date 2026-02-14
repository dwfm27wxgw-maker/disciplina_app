// ignore_for_file: curly_braces_in_flow_control_structures
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/movement.dart';
import '../models/plan.dart';

class LocalStore {
  static const _movementsKey = 'movements_v1';
  static const _planKey = 'plan_v1';

  // ---------------- Movements ----------------

  static Future<List<dynamic>> getMovements() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_movementsKey);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw);
    if (decoded is List) return decoded;
    return [];
  }

  static Future<void> saveMovement(Movement m) async {
    final list = await getMovements();
    final updated = List<dynamic>.from(list);
    updated.add(m.toJson());

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_movementsKey, jsonEncode(updated));
  }

  static Future<void> saveMovementsBulk(List<dynamic> newItems) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_movementsKey, jsonEncode(newItems));
  }

  static Future<void> deleteMovementById(String id) async {
    final list = await getMovements();
    final updated = <dynamic>[];

    for (final it in list) {
      if (it is Map && (it['id'] ?? '').toString() == id) continue;
      updated.add(it);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_movementsKey, jsonEncode(updated));
  }

  static Future<void> clearMovements() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_movementsKey);
  }

  // ---------------- Plan ----------------

  static Future<Plan?> getPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_planKey);
    if (raw == null || raw.isEmpty) return null;

    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return Plan.fromJson(decoded);
    if (decoded is Map)
      return Plan.fromJson(Map<String, dynamic>.from(decoded));
    return null;
  }

  static Future<void> savePlan(Plan plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_planKey, jsonEncode(plan.toJson()));
  }

  // Helper tolerante
  static Movement? tryParseMovement(dynamic m) {
    try {
      if (m is Movement) return m;
      if (m is Map) return Movement.fromJson(Map<String, dynamic>.from(m));
      return null;
    } catch (_) {
      return null;
    }
  }
}
