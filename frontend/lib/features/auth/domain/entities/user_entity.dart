import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String userId;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final String? financialGoal;

  const UserEntity({
    required this.userId,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    this.financialGoal,
  });

  @override
  List<Object?> get props => [userId, email, displayName, avatarUrl, financialGoal];
}
