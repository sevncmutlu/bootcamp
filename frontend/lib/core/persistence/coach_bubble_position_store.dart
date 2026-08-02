import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';

class CoachBubblePositionStore {
  CoachBubblePositionStore(this._preferences);

  static const _xKey = 'maki_coach_bubble_x_v1';
  static const _yKey = 'maki_coach_bubble_y_v1';

  final SharedPreferences _preferences;

  Offset? read() {
    try {
      final x = _preferences.getDouble(_xKey);
      final y = _preferences.getDouble(_yKey);
      if (x == null || y == null || !x.isFinite || !y.isFinite) return null;
      if (x < 0 || x > 1 || y < 0 || y > 1) return null;
      return Offset(x, y);
    } on Object {
      return null;
    }
  }

  Future<void> write(Offset position) async {
    final x = position.dx.clamp(0.0, 1.0);
    final y = position.dy.clamp(0.0, 1.0);
    try {
      await Future.wait([
        _preferences.setDouble(_xKey, x),
        _preferences.setDouble(_yKey, y),
      ]);
    } on Object {
      // The coach must remain usable even if browser storage is unavailable.
    }
  }
}
