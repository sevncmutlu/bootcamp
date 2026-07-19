import '../money/money.dart';

/// Sepet kaleminin fiyat eşleştirme biçimi.
enum BasketMatch { matched, proxy, excluded }

/// Laspeyres hesabında kullanılan sabit baz sepet kalemi.
final class BasketItem {
  factory BasketItem({
    required String id,
    required String categoryId,
    required Money baseUnitPrice,
    required Money currentUnitPrice,
    required int baseQuantity,
    required BasketMatch match,
  }) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', 'Kalem kimliği boş olamaz.');
    }
    if (categoryId.trim().isEmpty) {
      throw ArgumentError.value(
        categoryId,
        'categoryId',
        'Kategori kimliği boş olamaz.',
      );
    }
    if (baseUnitPrice.currency != currentUnitPrice.currency) {
      throw CurrencyMismatch(baseUnitPrice.currency, currentUnitPrice.currency);
    }
    if (baseUnitPrice.minorUnits <= 0) {
      throw ArgumentError.value(
        baseUnitPrice.minorUnits,
        'baseUnitPrice',
        'Baz fiyat sıfırdan büyük olmalıdır.',
      );
    }
    if (currentUnitPrice.minorUnits <= 0) {
      throw ArgumentError.value(
        currentUnitPrice.minorUnits,
        'currentUnitPrice',
        'Güncel fiyat sıfırdan büyük olmalıdır.',
      );
    }
    if (baseQuantity <= 0) {
      throw ArgumentError.value(
        baseQuantity,
        'baseQuantity',
        'Baz miktar sıfırdan büyük olmalıdır.',
      );
    }
    return BasketItem._(
      id: id,
      categoryId: categoryId,
      baseUnitPrice: baseUnitPrice,
      currentUnitPrice: currentUnitPrice,
      baseQuantity: baseQuantity,
      match: match,
    );
  }

  const BasketItem._({
    required this.id,
    required this.categoryId,
    required this.baseUnitPrice,
    required this.currentUnitPrice,
    required this.baseQuantity,
    required this.match,
  });

  final String id;
  final String categoryId;
  final Money baseUnitPrice;
  final Money currentUnitPrice;
  final int baseQuantity;
  final BasketMatch match;
}
