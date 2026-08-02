import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maki_app/core/personalization/goal_experience.dart';

void main() {
  test('dört finans amacı ayrı ürün ve flora deneyimi üretir', () {
    expect(GoalExperience.all, hasLength(4));
    expect(GoalExperience.all.map((goal) => goal.key).toSet(), hasLength(4));
    expect(
      GoalExperience.all
          .map((goal) => goal.species(const Locale('tr')))
          .toSet(),
      hasLength(4),
    );

    expect(
      GoalExperience.forKey('track_spending').species(const Locale('tr')),
      'Karayemiş Ağacı',
    );
    expect(
      GoalExperience.forKey('save_goal').species(const Locale('tr')),
      'Kermes Meşesi',
    );
    expect(
      GoalExperience.forKey('pay_debt').species(const Locale('tr')),
      'Mersin Ağacı',
    );
    expect(
      GoalExperience.forKey('learn_invest').species(const Locale('tr')),
      'Ilgın Ağacı',
    );
  });

  test('bilinmeyen amaç güvenli harcama takibi varsayımına döner', () {
    expect(GoalExperience.forKey('unknown').key, 'track_spending');
  });
}
