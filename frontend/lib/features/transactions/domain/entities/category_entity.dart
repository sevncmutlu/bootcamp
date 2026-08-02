import 'package:equatable/equatable.dart';

class CategoryEntity extends Equatable {
  final int id;
  final String name;
  final String colorHex;
  final String iconName;

  const CategoryEntity({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.iconName,
  });

  @override
  List<Object?> get props => [id, name, colorHex, iconName];
}
