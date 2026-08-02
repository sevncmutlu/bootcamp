import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:maki_app/features/auth/domain/entities/user_entity.dart';
import 'package:maki_app/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FlutterSecureStorage storage;

  static const String _userKey = 'maki_device_profile';

  UserEntity? _currentUser;
  bool _initialized = false;

  AuthRepositoryImpl({required this.storage});

  @override
  UserEntity? get currentUser => _currentUser;

  @override
  bool get isLoggedIn => _currentUser != null;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    final userJson = await storage.read(key: _userKey);
    if (userJson != null && userJson.isNotEmpty) {
      final decoded = jsonDecode(userJson);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Cihaz profili biçimi geçersiz.');
      }
      _currentUser = _mapToEntity(decoded);
    }
    _initialized = true;
  }

  @override
  Future<UserEntity> createProfile({
    required String displayName,
    required int age,
    String email = '',
    String? financialGoal,
  }) async {
    _validateAge(age);
    final profile = UserEntity(
      userId: _newDeviceProfileId(),
      email: email.trim(),
      displayName: displayName.trim(),
      age: age,
      financialGoal: financialGoal,
    );
    _currentUser = profile;
    await _saveUserToStorage(profile);
    return profile;
  }

  @override
  Future<void> deleteProfile() async {
    _currentUser = null;
    await storage.delete(key: _userKey);
  }

  @override
  Future<UserEntity> updateProfile({
    String? displayName,
    int? age,
    String? email,
    String? financialGoal,
    String? avatarUrl,
  }) async {
    final current = _currentUser;
    if (current == null) {
      throw StateError('Önce cihaz profili oluşturulmalıdır.');
    }
    if (age != null) _validateAge(age);

    final updatedUser = UserEntity(
      userId: current.userId,
      email: email?.trim() ?? current.email,
      displayName: displayName?.trim() ?? current.displayName,
      age: age ?? current.age,
      avatarUrl: avatarUrl ?? current.avatarUrl,
      financialGoal: financialGoal ?? current.financialGoal,
    );

    _currentUser = updatedUser;
    await _saveUserToStorage(updatedUser);
    return updatedUser;
  }

  Future<void> _saveUserToStorage(UserEntity user) async {
    final data = {
      'user_id': user.userId,
      'email': user.email,
      'display_name': user.displayName,
      'age': user.age,
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
      age: switch (data['age']) {
        final int value => value,
        final num value => value.toInt(),
        _ => null,
      },
      financialGoal: data['financial_goal'] as String?,
      avatarUrl: data['avatar_url'] as String?,
    );
  }

  String _newDeviceProfileId() {
    const alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
    final random = Random.secure();
    final suffix = List.generate(
      20,
      (_) => alphabet[random.nextInt(alphabet.length)],
      growable: false,
    ).join();
    return 'device_$suffix';
  }

  void _validateAge(int age) {
    if (age < 13 || age > 100) {
      throw const FormatException('Yaş 13 ile 100 arasında olmalıdır.');
    }
  }
}
