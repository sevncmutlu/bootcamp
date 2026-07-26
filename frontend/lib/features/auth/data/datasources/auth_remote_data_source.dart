import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:maki_app/core/network/api_config.dart';
import 'package:maki_app/features/auth/domain/entities/user_entity.dart';

class AuthResponseModel {
  final UserEntity user;
  final String accessToken;

  AuthResponseModel({required this.user, required this.accessToken});
}

abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> login(String email, String password);
  Future<AuthResponseModel> register(String email, String password, String displayName);
  Future<void> requestPasswordReset(String email);
  Future<void> resetPassword(String email, String newPassword);
  Future<UserEntity> getUserProfile(String token);
  Future<UserEntity> updateProfile(String token, {String? displayName, String? email, String? financialGoal, String? avatarUrl});
  Future<void> deleteAccount(String token);
  Future<void> changePassword(String token, String oldPassword, String newPassword);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final http.Client _client;

  AuthRemoteDataSourceImpl(this._client);

  @override
  Future<AuthResponseModel> login(String email, String password) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/v1/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return AuthResponseModel(
        user: _mapJsonToEntity(json),
        accessToken: json['access_token'] as String,
      );
    } else {
      throw Exception('Login failed: ${response.statusCode}');
    }
  }

  @override
  Future<AuthResponseModel> register(String email, String password, String displayName) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/v1/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'display_name': displayName,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return AuthResponseModel(
        user: _mapJsonToEntity(json),
        accessToken: json['access_token'] as String,
      );
    } else {
      throw Exception('Registration failed: ${response.statusCode}');
    }
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/v1/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      throw Exception('Password reset request failed: ${response.statusCode}');
    }
  }

  @override
  Future<UserEntity> getUserProfile(String token) async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/v1/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return _mapJsonToEntity(jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to get user profile: ${response.statusCode}');
    }
  }

  @override
  Future<UserEntity> updateProfile(
    String token, {
    String? displayName,
    String? email,
    String? financialGoal,
    String? avatarUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (displayName != null) updates['display_name'] = displayName;
    if (email != null) updates['email'] = email;
    if (financialGoal != null) updates['financial_goal'] = financialGoal;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    final response = await _client.put(
      Uri.parse('${ApiConfig.baseUrl}/v1/auth/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(updates),
    );

    if (response.statusCode == 200) {
      return _mapJsonToEntity(jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to update profile: ${response.statusCode}');
    }
  }

  @override
  Future<void> deleteAccount(String token) async {
    final response = await _client.delete(
      Uri.parse('${ApiConfig.baseUrl}/v1/auth/account'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete account: ${response.statusCode}');
    }
  }

  @override
  Future<void> resetPassword(String email, String newPassword) async {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/v1/auth/reset-password'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'new_password': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to reset password: ${response.statusCode}');
    }
  }

  @override
  Future<void> changePassword(String token, String oldPassword, String newPassword) async {
    final response = await _client.put(
      Uri.parse('${ApiConfig.baseUrl}/v1/auth/change-password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'old_password': oldPassword,
        'new_password': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to change password: ${response.statusCode}');
    }
  }

  UserEntity _mapJsonToEntity(Map<String, dynamic> json) {
    return UserEntity(
      userId: json['user_id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String,
      financialGoal: json['financial_goal'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}
