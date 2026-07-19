import 'lints_state.dart';

List<double> finiteVector(
  List<num> values, {
  required int dimension,
  required String field,
}) {
  if (values.length != dimension) {
    throw LinTsContractException('$field boyutu $dimension olmalıdır.');
  }
  final result = <double>[];
  for (final value in values) {
    final converted = value.toDouble();
    if (!converted.isFinite) {
      throw LinTsContractException('$field sonlu değerler taşımalıdır.');
    }
    result.add(converted);
  }
  return result;
}

double dot(List<double> left, List<double> right) {
  var result = 0.0;
  for (var index = 0; index < left.length; index++) {
    result += left[index] * right[index];
  }
  return result;
}

bool sameVector(List<double> left, List<double> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}
