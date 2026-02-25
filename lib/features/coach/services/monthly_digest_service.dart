import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../core/storage/local_store.dart';

class MonthlyDigest {
  final String headline;
  final String actionLine;
  final String fullBody;

  // Getters de compatibilidad (por si tu UI antigua los usa)
  String get title => headline;
  String get subtitle => actionLine;
  String get body => fullBody;

  const MonthlyDigest({
    required this.headline,
    required this.actionLine,
    required this.fullBody,
  });
}

class MonthlyDigestService {
  /// Genera un digest mensual basado en:
  /// - Plan (aportación mensual + pesos objetivo por ticker)
  /// - Movimientos del mes (para saber cuánto queda)
  ///
  /// Es tolerante a movimientos Map u objeto.
  static Future<MonthlyDigest> buildMonthlyDigest() async {
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 1);

      final movements = await _safeGetMovements();
      final plan = await _safeGetPlan();

      // Si no hay plan, guía al usuario
      final monthly = _getNum(plan, ['monthlyContribution', 'monthly', 'amount', 'contribution']) ?? 50.0;
      final weights = _getMap(plan, ['targetWeights', 'weights', 'allocations']) ?? <String, dynamic>{};

      final investedThisMonth = _sumInvestedInRange(movements, start, end);
      final remaining = max(0.0, monthly - investedThisMonth);

      if (weights.isEmpty) {
        return MonthlyDigest(
          headline: 'Configura tu Plan',
          actionLine: 'Añade tus ETFs y pesos objetivo.',
          fullBody:
              'Ahora mismo puedo darte recordatorios, pero para recomendar “qué comprar” necesito tu Plan: '
              'aportación mensual y pesos por ETF (por ejemplo IWLE 60%, EUNU 30%, IS3N 10%).',
        );
      }

      // Reparto simple del restante según pesos
      final alloc = <String, double>{};
      weights.forEach((k, v) {
        final w = (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0.0;
        if (w > 0) alloc[k.toUpperCase().trim()] = w;
      });

      // Normaliza por si no suma 1
      final sumW = alloc.values.fold<double>(0.0, (a, b) => a + b);
      final norm = (sumW <= 0.000001) ? alloc : alloc.map((k, v) => MapEntry(k, v / sumW));

      final euros = norm.map((t, w) => MapEntry(t, remaining * w));
      final sorted = euros.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final top = sorted.take(3).where((e) => e.value >= 1.0).toList();

      if (remaining <= 0.01) {
        return MonthlyDigest(
          headline: 'Mes completado ✅',
          actionLine: 'Este mes ya has cubierto tu aportación.',
          fullBody:
              'Invertido este mes: ${_eur(investedThisMonth)}.\n'
              'Aportación objetivo: ${_eur(monthly)}.\n\n'
              'Siguiente paso: mantener disciplina y preparar el próximo mes.',
        );
      }

      final buyLine = top.isEmpty
          ? 'Reparte ${_eur(remaining)} según tu Plan.'
          : 'Compra: ${top.map((e) => '${_eur(e.value)} ${e.key}').join(' + ')}';

      return MonthlyDigest(
        headline: 'Te quedan ${_eur(remaining)} este mes',
        actionLine: buyLine,
        fullBody:
            'Invertido este mes: ${_eur(investedThisMonth)}\n'
            'Objetivo del mes: ${_eur(monthly)}\n'
            'Restante: ${_eur(remaining)}\n\n'
            'Esto es un reparto por pesos objetivo (MVP). Más adelante podemos ajustarlo por desviación real de cartera.',
      );
    } catch (e, st) {
      debugPrint('MonthlyDigestService error: $e\n$st');
      return const MonthlyDigest(
        headline: 'Coach mensual',
        actionLine: 'No pude calcular la recomendación.',
        fullBody:
            'He tenido un problema leyendo tu Plan o movimientos. '
            'Prueba a abrir Home una vez, o revisa que tienes Plan configurado.',
      );
    }
  }

  // ---- helpers (tolerantes) ----

  static Future<List<dynamic>> _safeGetMovements() async {
    try {
      final m = await LocalStore.getMovements();
      if (m is List) return m.cast<dynamic>();
      return <dynamic>[];
    } catch (_) {
      return <dynamic>[];
    }
  }

  static Future<dynamic> _safeGetPlan() async {
    try {
      // Si existe en tu LocalStore
      final p = await LocalStore.getPlan();
      return p;
    } catch (_) {
      return null;
    }
  }

  static double _sumInvestedInRange(List<dynamic> movements, DateTime start, DateTime end) {
    double sum = 0.0;
    for (final mv in movements) {
      final d = _getDate(mv, ['date', 'createdAt', 'timestamp']);
      if (d == null) continue;
      if (d.isBefore(start) || !d.isBefore(end)) continue;

      final amount = _getNum(mv, ['amount', 'value', 'eur', 'euros']) ?? 0.0;
      sum += amount;
    }
    return sum;
  }

  static DateTime? _getDate(dynamic obj, List<String> keys) {
    for (final k in keys) {
      final v = _getAny(obj, k);
      if (v == null) continue;

      if (v is DateTime) return v;
      if (v is int) {
        // ms epoch likely
        if (v > 1000000000000) return DateTime.fromMillisecondsSinceEpoch(v);
        return DateTime.fromMillisecondsSinceEpoch(v * 1000);
      }
      if (v is String) {
        final parsed = DateTime.tryParse(v);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  static double? _getNum(dynamic obj, List<String> keys) {
    for (final k in keys) {
      final v = _getAny(obj, k);
      if (v == null) continue;
      if (v is num) return v.toDouble();
      final p = double.tryParse('$v');
      if (p != null) return p;
    }
    return null;
  }

  static Map<String, dynamic>? _getMap(dynamic obj, List<String> keys) {
    for (final k in keys) {
      final v = _getAny(obj, k);
      if (v is Map) {
        return v.map((key, value) => MapEntry('$key', value));
      }
    }
    return null;
  }

  static dynamic _getAny(dynamic obj, String key) {
    try {
      if (obj == null) return null;
      if (obj is Map) return obj[key] ?? obj[key.toString()];
      // fallback: try getter via dynamic (may throw)
      final dyn = obj as dynamic;
      switch (key) {
        case 'date':
          return dyn.date;
        case 'amount':
          return dyn.amount;
        case 'monthlyContribution':
          return dyn.monthlyContribution;
        case 'targetWeights':
          return dyn.targetWeights;
      }
    } catch (_) {}
    return null;
  }

  static String _eur(double v) {
    // redondeo simple y legible
    final r = (v * 100).round() / 100.0;
    if ((r - r.roundToDouble()).abs() < 0.000001) {
      return '${r.round()}€';
    }
    return '${r.toStringAsFixed(2)}€';
  }
}