import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String userId;
  final String email;
  final String displayName;
  final int? age;
  final String? avatarUrl;
  final String? financialGoal;

  const UserEntity({
    required this.userId,
    required this.email,
    required this.displayName,
    this.age,
    this.avatarUrl,
    this.financialGoal,
  });

  @override
  List<Object?> get props => [
    userId,
    email,
    displayName,
    age,
    avatarUrl,
    financialGoal,
  ];
}
