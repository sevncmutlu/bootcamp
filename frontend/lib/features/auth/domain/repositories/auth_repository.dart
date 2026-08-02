import 'package:maki_app/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<void> initialize();
  UserEntity? get currentUser;
  bool get isLoggedIn;

  Future<UserEntity> createProfile({
    required String displayName,
    required int age,
    String email = '',
    String? financialGoal,
  });
  Future<void> deleteProfile();
  Future<UserEntity> updateProfile({
    String? displayName,
    int? age,
    String? email,
    String? avatarUrl,
    String? financialGoal,
  });
}
