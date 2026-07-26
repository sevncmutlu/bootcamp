import 'package:maki_app/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<void> initialize();
  UserEntity? get currentUser;
  String? get accessToken;
  bool get isLoggedIn;
  
  Future<UserEntity> login({required String email, required String password});
  Future<UserEntity> register({required String email, required String password, required String displayName});
  Future<void> logout();
  Future<void> deleteAccount();
  Future<void> resetPassword({required String email, required String newPassword});
  Future<void> changePassword({required String oldPassword, required String newPassword});
  Future<UserEntity> updateProfile({String? displayName, String? email, String? avatarUrl, String? financialGoal});
}
