/// LightGBM model sözleşmesi desteklenmiyor.
final class ModelContractException implements Exception {
  const ModelContractException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Model girdisi sözleşmeye uymuyor.
final class ModelInputException implements Exception {
  const ModelInputException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Ayrıştırılmış ikili LightGBM modeli.
final class LightGbmModel {
  LightGbmModel({
    required List<String> featureNames,
    required List<LightGbmTree> trees,
    required this.sigmoid,
  }) : featureNames = List.unmodifiable(featureNames),
       trees = List.unmodifiable(trees);

  final List<String> featureNames;
  final List<LightGbmTree> trees;
  final double sigmoid;
}

/// Tek bir LightGBM karar ağacı.
final class LightGbmTree {
  const LightGbmTree({required this.root});

  final LightGbmNode root;
}

/// Karar ağacı düğümü.
sealed class LightGbmNode {
  const LightGbmNode();
}

/// Dalın eksik değer yorumlama biçimi.
enum LightGbmMissingType { none, zero, nan }

/// Karar ağacı yaprağı.
final class LightGbmLeaf extends LightGbmNode {
  const LightGbmLeaf(this.value);

  final double value;
}

/// Karar ağacı dalı.
final class LightGbmBranch extends LightGbmNode {
  LightGbmBranch.numeric({
    required this.featureIndex,
    required double threshold,
    required this.defaultLeft,
    required this.missingType,
    required this.left,
    required this.right,
  }) : numericThreshold = threshold,
       categories = null;

  LightGbmBranch.categorical({
    required this.featureIndex,
    required Set<int> categories,
    required this.defaultLeft,
    required this.missingType,
    required this.left,
    required this.right,
  }) : numericThreshold = null,
       categories = Set.unmodifiable(categories);

  final int featureIndex;
  final double? numericThreshold;
  final Set<int>? categories;
  final bool defaultLeft;
  final LightGbmMissingType missingType;
  final LightGbmNode left;
  final LightGbmNode right;
}
