import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class DebtPlanDefinition {
  const DebtPlanDefinition({
    required this.id,
    required this.name,
    required this.primary,
    required this.primaryDirection,
    required this.tieBreaker,
    required this.tieBreakerDirection,
    required this.allocation,
  });

  final String id;
  final String name;
  final String primary;
  final String primaryDirection;
  final String tieBreaker;
  final String tieBreakerDirection;
  final String allocation;

  String get strategyCode => [
    'custom',
    primary,
    primaryDirection,
    tieBreaker,
    tieBreakerDirection,
    allocation,
  ].join('|');

  DebtPlanDefinition copyWith({String? id, String? name}) => DebtPlanDefinition(
    id: id ?? this.id,
    name: name ?? this.name,
    primary: primary,
    primaryDirection: primaryDirection,
    tieBreaker: tieBreaker,
    tieBreakerDirection: tieBreakerDirection,
    allocation: allocation,
  );

  Map<String, Object?> toJson() => {
    'schemaVersion': 1,
    'id': id,
    'name': name,
    'primary': primary,
    'primaryDirection': primaryDirection,
    'tieBreaker': tieBreaker,
    'tieBreakerDirection': tieBreakerDirection,
    'allocation': allocation,
  };

  static DebtPlanDefinition? fromJson(Object? value) {
    if (value is! Map<String, dynamic> || value['schemaVersion'] != 1) {
      return null;
    }
    final fields = [
      value['id'],
      value['name'],
      value['primary'],
      value['primaryDirection'],
      value['tieBreaker'],
      value['tieBreakerDirection'],
      value['allocation'],
    ];
    if (fields.any((field) => field is! String || field.isEmpty)) return null;
    return DebtPlanDefinition(
      id: value['id'] as String,
      name: value['name'] as String,
      primary: value['primary'] as String,
      primaryDirection: value['primaryDirection'] as String,
      tieBreaker: value['tieBreaker'] as String,
      tieBreakerDirection: value['tieBreakerDirection'] as String,
      allocation: value['allocation'] as String,
    );
  }
}

class DebtPlanLocalDataSource {
  DebtPlanLocalDataSource(this._preferences);

  final SharedPreferences _preferences;
  static const _key = 'maki_debt_plans_v1';

  List<DebtPlanDefinition> load() {
    final raw = _preferences.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List<dynamic>) return const [];
      return decoded
          .map(DebtPlanDefinition.fromJson)
          .whereType<DebtPlanDefinition>()
          .toList(growable: false);
    } on FormatException {
      return const [];
    }
  }

  Future<void> save(List<DebtPlanDefinition> plans) async {
    await _preferences.setString(
      _key,
      jsonEncode(plans.map((plan) => plan.toJson()).toList(growable: false)),
    );
  }
}
