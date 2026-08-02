import 'package:flutter_test/flutter_test.dart';
import 'package:maki_app/core/persistence/coach_bubble_position_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('normalized coach position survives a new store instance', () async {
    final preferences = await SharedPreferences.getInstance();
    final store = CoachBubblePositionStore(preferences);

    await store.write(const Offset(0, 0.38));

    final restored = CoachBubblePositionStore(preferences).read();
    expect(restored, const Offset(0, 0.38));
  });

  test(
    'saved coordinates are clamped to the available normalized range',
    () async {
      final preferences = await SharedPreferences.getInstance();
      final store = CoachBubblePositionStore(preferences);

      await store.write(const Offset(-2, 4));

      expect(store.read(), const Offset(0, 1));
    },
  );

  test('invalid browser storage is ignored safely', () async {
    SharedPreferences.setMockInitialValues({
      'maki_coach_bubble_x_v1': 'not-a-number',
      'maki_coach_bubble_y_v1': 0.5,
    });
    final preferences = await SharedPreferences.getInstance();

    expect(CoachBubblePositionStore(preferences).read(), isNull);
  });
}
