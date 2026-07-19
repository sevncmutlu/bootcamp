import 'dart:math' as math;

/// Matris sayısal olarak güvenli çözülemedi.
final class NumericalStabilityException implements Exception {
  const NumericalStabilityException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Pozitif tanımlı sistemleri ters matris almadan çözer.
abstract final class Cholesky {
  static CholeskyDecomposition decompose(
    List<List<double>> matrix, {
    double regularization = 0,
  }) {
    _validateMatrix(matrix, regularization);
    final dimension = matrix.length;
    final lower = List.generate(
      dimension,
      (_) => List<double>.filled(dimension, 0),
    );
    for (var row = 0; row < dimension; row++) {
      for (var column = 0; column <= row; column++) {
        var sum = matrix[row][column];
        if (row == column) {
          sum += regularization;
        }
        for (var index = 0; index < column; index++) {
          sum -= lower[row][index] * lower[column][index];
        }
        if (row == column) {
          if (!sum.isFinite || sum <= 0) {
            throw const NumericalStabilityException(
              'Matris pozitif tanımlı değil.',
            );
          }
          lower[row][column] = math.sqrt(sum);
        } else {
          final value = sum / lower[column][column];
          if (!value.isFinite) {
            throw const NumericalStabilityException(
              'Cholesky ayrışımı sonlu değer üretmedi.',
            );
          }
          lower[row][column] = value;
        }
      }
    }
    return CholeskyDecomposition._(lower);
  }

  static List<double> solve(
    List<List<double>> matrix,
    List<double> rightHandSide, {
    double regularization = 0,
  }) => decompose(matrix, regularization: regularization).solve(rightHandSide);

  static void _validateMatrix(
    List<List<double>> matrix,
    double regularization,
  ) {
    if (matrix.isEmpty || matrix.length > 256) {
      throw const NumericalStabilityException('Matris boyutu geçersiz.');
    }
    if (!regularization.isFinite || regularization < 0) {
      throw const NumericalStabilityException(
        'Düzenlileştirme negatif veya sonlu olmayan değer olamaz.',
      );
    }
    final dimension = matrix.length;
    for (var row = 0; row < dimension; row++) {
      if (matrix[row].length != dimension) {
        throw const NumericalStabilityException('Matris kare olmalıdır.');
      }
      for (var column = 0; column < dimension; column++) {
        final value = matrix[row][column];
        if (!value.isFinite) {
          throw const NumericalStabilityException(
            'Matris sonlu değerler taşımalıdır.',
          );
        }
        final opposite = matrix[column][row];
        final scale = math.max(1.0, math.max(value.abs(), opposite.abs()));
        if ((value - opposite).abs() > 1e-12 * scale) {
          throw const NumericalStabilityException('Matris simetrik olmalıdır.');
        }
      }
    }
  }
}

/// Cholesky alt üçgen ayrışımı.
final class CholeskyDecomposition {
  CholeskyDecomposition._(List<List<double>> lower)
    : _lower = List.unmodifiable(lower.map(List<double>.unmodifiable));

  final List<List<double>> _lower;

  List<double> solve(List<double> rightHandSide) {
    final intermediate = _solveLower(rightHandSide);
    return _solveTranspose(intermediate);
  }

  /// Standart normal örneğini kesinlik matrisinin kovaryansına taşır.
  List<double> transformStandardNormal(List<double> values) =>
      _solveTranspose(_validateRightHandSide(values));

  List<double> _solveLower(List<double> rightHandSide) {
    final values = _validateRightHandSide(rightHandSide);
    final result = List<double>.filled(_lower.length, 0);
    for (var row = 0; row < _lower.length; row++) {
      var sum = values[row];
      for (var column = 0; column < row; column++) {
        sum -= _lower[row][column] * result[column];
      }
      result[row] = sum / _lower[row][row];
    }
    return result;
  }

  List<double> _solveTranspose(List<double> rightHandSide) {
    final values = _validateRightHandSide(rightHandSide);
    final result = List<double>.filled(_lower.length, 0);
    for (var row = _lower.length - 1; row >= 0; row--) {
      var sum = values[row];
      for (var column = row + 1; column < _lower.length; column++) {
        sum -= _lower[column][row] * result[column];
      }
      result[row] = sum / _lower[row][row];
    }
    return result;
  }

  List<double> _validateRightHandSide(List<double> values) {
    if (values.length != _lower.length ||
        values.any((value) => !value.isFinite)) {
      throw const NumericalStabilityException(
        'Çözüm vektörünün boyutu veya değeri geçersiz.',
      );
    }
    return values;
  }
}
