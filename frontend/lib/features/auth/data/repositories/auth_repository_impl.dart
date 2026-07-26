import 'dart:convert';
import 'package:maki_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:maki_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:maki_app/features/auth/domain/entities/user_entity.dart';
import 'package:maki_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource localDataSource;
  final AuthRemoteDataSource remoteDataSource;
  final FlutterSecureStorage storage;

  static const String _userKey = 'maki_auth_user';

  UserEntity? _currentUser;
  String? _accessToken;
  bool _initialized = false;

  AuthRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.storage,
  });

  @override
  UserEntity? get currentUser => _currentUser;

  @override
  String? get accessToken => _accessToken;

  @override
  bool get isLoggedIn => _currentUser != null;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      _accessToken = await localDataSource.getAccessToken();
      final userStr = await storage.read(key: _userKey);
      if (userStr != null) {
        final data = jsonDecode(userStr) as Map<String, dynamic>;
        _currentUser = _mapToEntity(data);
      }
    } catch (e) {
      // ignore
    } finally {
      _initialized = true;
    }
  }

  @override
  Future<UserEntity> login({required String email, required String password}) async {
    final response = await remoteDataSource.login(email, password);
    _accessToken = response.accessToken;
    _currentUser = response.user;

    await localDataSource.saveAccessToken(_accessToken!);
    await _saveUserToStorage(_currentUser!);

    return _currentUser!;
  }

  @override
  Future<UserEntity> register({required String email, required String password, required String displayName}) async {
    final response = await remoteDataSource.register(email, password, displayName);
    _accessToken = response.accessToken;
    _currentUser = response.user;

    await localDataSource.saveAccessToken(_accessToken!);
    await _saveUserToStorage(_currentUser!);

    return _currentUser!;
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
    _accessToken = null;
    await localDataSource.clearSession();
    await storage.delete(key: _userKey);
  }

  @override
  Future<void> deleteAccount() async {
    if (_accessToken != null) {
      await remoteDataSource.deleteAccount(_accessToken!);
    }
    await logout();
  }

  Future<void> requestPasswordReset(String email) async {
    await remoteDataSource.requestPasswordReset(email);
  }

  @override
  Future<void> resetPassword({required String email, required String newPassword}) async {
    await remoteDataSource.resetPassword(email, newPassword);
  }

  @override
  Future<void> changePassword({required String oldPassword, required String newPassword}) async {
    if (_accessToken == null) throw Exception('Not authenticated');
    await remoteDataSource.changePassword(_accessToken!, oldPassword, newPassword);
  }

  Future<void> refreshProfile() async {
    if (_accessToken == null) return;
    try {
      _currentUser = await remoteDataSource.getUserProfile(_accessToken!);
      await _saveUserToStorage(_currentUser!);
    } catch (e) {
      // ignore
    }
  }

  @override
  Future<UserEntity> updateProfile({
    String? displayName,
    String? email,
    String? financialGoal,
    String? avatarUrl,
  }) async {
    if (_accessToken == null) {
      throw Exception('Not authenticated');
    }

    final updatedUser = await remoteDataSource.updateProfile(
      _accessToken!,
      displayName: displayName,
      email: email,
      financialGoal: financialGoal,
      avatarUrl: avatarUrl,
    );

    _currentUser = updatedUser;
    await _saveUserToStorage(_currentUser!);
    return _currentUser!;
  }

  Future<void> _saveUserToStorage(UserEntity user) async {
    final data = {
      'user_id': user.userId,
      'email': user.email,
      'display_name': user.displayName,
      'financial_goal': user.financialGoal,
      'avatar_url': user.avatarUrl,
    };
    await storage.write(key: _userKey, value: jsonEncode(data));
  }

  UserEntity _mapToEntity(Map<String, dynamic> data) {
    return UserEntity(
      userId: data['user_id'] as String,
      email: data['email'] as String,
      displayName: data['display_name'] as String,
      financialGoal: data['financial_goal'] as String?,
      avatarUrl: data['avatar_url'] as String?,
    );
  }
}
