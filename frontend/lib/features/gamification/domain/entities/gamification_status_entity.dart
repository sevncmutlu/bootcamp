import 'package:equatable/equatable.dart';

class GamificationStatusEntity extends Equatable {
  final int xp;
  final int level;

  const GamificationStatusEntity({
    required this.xp,
    required this.level,
  });

  @override
  List<Object?> get props => [xp, level];
}
