// ignore_for_file: curly_braces_in_flow_control_structures
import 'dart:convert';

class Plan {
  final double monthlyContribution;
  final Map<String, double> targetWeights;

  const Plan({
    required this.monthlyContribution,
    required this.targetWeights,
  });

  static Plan defaultPlan() {
    // Default seguro (puedes cambiarlo en EditPlanScreen)
    return const Plan(
      monthlyContribution: 50.0,
      targetWeights: <String, double>{},
    );
  }

  Plan copyWith({
    double? monthlyContribution,
    Map<String, double>? targetWeights,
  }) {
    return Plan(
      monthlyContribution: monthlyContribution ?? this.monthlyContribution,
      targetWeights: targetWeights ?? this.targetWeights,
    );
  }

  factory Plan.fromJson(dynamic input) {
    Map<String, dynamic> json;

    // Acepta String JSON o Map
    if (input is String) {
      try {
        final decoded = jsonDecode(input);
        json = decoded is Map
            ? Map<String, dynamic>.from(decoded)
            : <String, dynamic>{};
      } catch (_) {
        json = <String, dynamic>{};
      }
    } else if (input is Map) {
      json = Map<String, dynamic>.from(input);
    } else {
      json = <String, dynamic>{};
    }

    double monthly = 50.0;
    try {
      final v = json['monthlyContribution'];
      if (v is num)
        monthly = v.toDouble();
      else if (v != null) monthly = double.tryParse(v.toString()) ?? monthly;
    } catch (_) {}

    final weights = <String, double>{};
    try {
      dynamic tw = json['targetWeights'];

      // Si viene como String JSON
      if (tw is String) {
        try {
          tw = jsonDecode(tw);
        } catch (_) {
          tw = null;
        }
      }

      if (tw is Map) {
        final m = Map<String, dynamic>.from(tw);
        m.forEach((k, v) {
          final t = k.toString().trim().toUpperCase();
          if (t.isEmpty) return;
          final w = (v is num)
              ? v.toDouble()
              : (double.tryParse(v.toString()) ?? 0.0);
          weights[t] = w;
        });
      }
    } catch (_) {}

    return Plan(monthlyContribution: monthly, targetWeights: weights);
  }

  Map<String, dynamic> toJson() => {
        'monthlyContribution': monthlyContribution,
        'targetWeights': targetWeights,
      };
}
