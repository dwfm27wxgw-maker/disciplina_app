import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/plan.dart';

class LocalStore {
  // Keys
  static const String _kTickers = 'tickers_v1';
  static const String _kMovements = 'movements_v1';
  static const String _kPlan = 'plan_v1';

  // -------------------------
  // Tickers
  // -------------------------
  static Future<List<String>> getTickers() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_kTickers) ?? <String>[];
    return list.map((e) => e.toString()).toList();
  }

  static Future<void> saveTickers(List<String> tickers) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _kTickers,
      tickers
          .map((e) => e.toUpperCase().trim())
          .where((e) => e.isNotEmpty)
          .toList(),
    );
  }

  // -------------------------
  // Movements (tolerante)
  // Guardamos como List<String> donde cada item es JSON de un movimiento.
  // Leemos también formatos antiguos si existieran.
  // -------------------------
  static Map<String, dynamic>? _toMap(dynamic m) {
    if (m == null) return null;

    if (m is Map<String, dynamic>) return m;
    if (m is Map) {
      return m.map((k, v) => MapEntry(k.toString(), v));
    }

    // intenta toJson()
    try {
      final j = (m as dynamic).toJson();
      if (j is Map) {
        return j.map((k, v) => MapEntry(k.toString(), v));
      }
    } catch (_) {}

    return null;
  }

  static Future<List<dynamic>> getMovements() async {
    final prefs = await SharedPreferences.getInstance();

    // Formato principal: List<String> (cada string es JSON)
    final list = prefs.getStringList(_kMovements);
    if (list != null) {
      final out = <dynamic>[];
      for (final s in list) {
        try {
          final decoded = jsonDecode(s);
          if (decoded is Map) {
            out.add(decoded.map((k, v) => MapEntry(k.toString(), v)));
          }
        } catch (_) {}
      }
      return out;
    }

    // Compatibilidad: si alguien guardó un JSON string con lista
    final raw = prefs.getString(_kMovements);
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded.map((e) => _toMap(e) ?? e).toList();
        }
      } catch (_) {}
    }

    return <dynamic>[];
  }

  static Future<void> saveMovementsBulk(List<dynamic> movements) async {
    final prefs = await SharedPreferences.getInstance();

    final jsonList = <String>[];
    for (final m in movements) {
      final map = _toMap(m);
      if (map == null) continue;

      // Asegura campos mínimos
      map['ticker'] = (map['ticker'] ?? 'UNKNOWN')
          .toString()
          .toUpperCase()
          .trim();
      map['amount'] = map['amount'] ?? 0;
      map['date'] = map['date'] ?? DateTime.now().toIso8601String();
      map['id'] = map['id'] ?? '${DateTime.now().microsecondsSinceEpoch}';

      jsonList.add(jsonEncode(map));
    }

    await prefs.setStringList(_kMovements, jsonList);
  }

  static Future<void> saveMovement(dynamic movement) async {
    final list = await getMovements();
    final map = _toMap(movement);
    if (map == null) return;

    // Insert al principio
    list.insert(0, map);
    await saveMovementsBulk(list);
  }

  // Alias por si en otras pantallas lo usabas con otro nombre
  static Future<void> addMovement(dynamic movement) => saveMovement(movement);

  // -------------------------
  // Plan
  // -------------------------
  static Future<Plan?> getPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPlan);
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final map = decoded.map((k, v) => MapEntry(k.toString(), v));
        // Intentamos Plan.fromJson(map)
        try {
          // ignore: invalid_use_of_visible_for_testing_member, avoid_dynamic_calls
          return Plan.fromJson(map);
        } catch (_) {
          // Si tu Plan no tiene fromJson, no rompemos
          return null;
        }
      }
    } catch (_) {}

    return null;
  }

  static Future<void> savePlan(Plan plan) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      // ignore: avoid_dynamic_calls
      final m = (plan as dynamic).toJson();
      await prefs.setString(_kPlan, jsonEncode(m));
      return;
    } catch (_) {
      // fallback: intenta guardar algo mínimo
      await prefs.setString(_kPlan, jsonEncode({}));
    }
  }
}
