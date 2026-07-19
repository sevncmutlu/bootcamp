import 'package:maki_finance_core/src/lints/cholesky.dart';
import 'package:test/test.dart';

void main() {
  test('pozitif tanımlı sistem çözülür', () {
    final solution = Cholesky.solve(
      const [
        [4.0, 2.0],
        [2.0, 3.0],
      ],
      const [6.0, 7.0],
    );

    expect(solution[0], closeTo(0.5, 1e-12));
    expect(solution[1], closeTo(2.0, 1e-12));
  });

  test('asimetrik matris reddedilir', () {
    expect(
      () => Cholesky.solve(
        const [
          [2.0, 1.0],
          [0.0, 2.0],
        ],
        const [1.0, 1.0],
      ),
      throwsA(isA<NumericalStabilityException>()),
    );
  });

  test('pozitif tanımlı olmayan matris reddedilir', () {
    expect(
      () => Cholesky.solve(
        const [
          [1.0, 2.0],
          [2.0, 1.0],
        ],
        const [1.0, 1.0],
      ),
      throwsA(isA<NumericalStabilityException>()),
    );
  });
}
