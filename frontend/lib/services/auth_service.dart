import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:maki_app/config/api_config.dart';

class UserProfile {
  const UserProfile({
    required this.userId,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    this.financialGoal,
  });

  final String userId;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final String? financialGoal;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      financialGoal: json['financial_goal'] as String?,
    );
  }

  static ImageProvider getAvatarImage(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return const AssetImage('assets/mascot/maki_avatar.webp');
    }
    if (avatarUrl.startsWith('assets/')) {
      return AssetImage(avatarUrl);
    }
    if (avatarUrl.startsWith('http://') ||
        avatarUrl.startsWith('https://') ||
        avatarUrl.startsWith('blob:') ||
        avatarUrl.startsWith('data:')) {
      return NetworkImage(avatarUrl);
    }
    if (!kIsWeb) {
      try {
        final file = File(avatarUrl);
        if (file.existsSync()) {
          return FileImage(file);
        }
      } catch (_) {}
    }
    return const AssetImage('assets/mascot/maki_avatar.webp');
  }
}

class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const String _tokenKey = 'maki_auth_token';
  static const String _userKey = 'maki_auth_user';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  UserProfile? _currentUser;
  String? _accessToken;
  bool _initialized = false;

  UserProfile? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isInitialized => _initialized;
  String? get accessToken => _accessToken;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      _accessToken = await _storage.read(key: _tokenKey);
      final userStr = await _storage.read(key: _userKey);
      if (userStr != null) {
        _currentUser = UserProfile.fromJson(
          jsonDecode(userStr) as Map<String, dynamic>,
        );
      }
    } catch (e) {
      debugPrint('Auth initialization error: $e');
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/v1/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'display_name': displayName,
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      final msg = _extractErrorMessage(response.bodyBytes, 'Registration failed');
      throw Exception(msg);
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    _accessToken = data['access_token'] as String;
    _currentUser = UserProfile.fromJson(data);

    await _storage.write(key: _tokenKey, value: _accessToken);
    await _storage.write(key: _userKey, value: jsonEncode(data));

    notifyListeners();
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/v1/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      final msg = _extractErrorMessage(response.bodyBytes, 'Login failed');
      throw Exception(msg);
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    _accessToken = data['access_token'] as String;
    _currentUser = UserProfile.fromJson(data);

    await _storage.write(key: _tokenKey, value: _accessToken);
    await _storage.write(key: _userKey, value: jsonEncode(data));

    notifyListeners();
  }

  Future<void> updateProfile({
    String? displayName,
    String? email,
    String? avatarUrl,
    String? financialGoal,
  }) async {
    if (_accessToken == null) return;

    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/v1/auth/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_accessToken',
      },
      body: jsonEncode({
        if (displayName != null) 'display_name': displayName,
        if (email != null) 'email': email,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (financialGoal != null) 'financial_goal': financialGoal,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _currentUser = UserProfile.fromJson(data);
      await _storage.write(key: _userKey, value: jsonEncode(data));
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _accessToken = null;
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    if (_accessToken != null) {
      try {
        await http.delete(
          Uri.parse('${ApiConfig.baseUrl}/v1/auth/account'),
          headers: {
            'Authorization': 'Bearer $_accessToken',
          },
        );
      } catch (e) {
        debugPrint('Delete account error: $e');
      }
    }
    await logout();
  }

  Future<void> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/v1/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'new_password': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final msg = body['detail'] ?? 'Password reset failed';
      throw Exception(msg.toString());
    }
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (_accessToken == null) return;
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/v1/auth/change-password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_accessToken',
      },
      body: jsonEncode({
        'old_password': oldPassword,
        'new_password': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      String errorMessage = '';
      try {
        final rawBody = response.body;
        if (rawBody.isNotEmpty) {
          final body = jsonDecode(rawBody);
          if (body is Map<String, dynamic>) {
            final detail = body['detail'];
            if (detail is String && detail.isNotEmpty) {
              errorMessage = detail;
            } else if (detail is List && detail.isNotEmpty) {
              final firstErr = detail.first;
              if (firstErr is Map && firstErr.containsKey('msg')) {
                errorMessage = firstErr['msg'].toString();
              }
            }
          }
        }
      } catch (_) {}

      if (errorMessage.isEmpty) {
        errorMessage = response.statusCode == 400
            ? 'Mevcut şifre yanlış.'
            : 'Change password failed (${response.statusCode})';
      }
      throw Exception(errorMessage);
    }
  }

  static String _extractErrorMessage(List<int> bodyBytes, String fallback) {
    try {
      final decodedString = utf8.decode(bodyBytes);
      final body = jsonDecode(decodedString) as Map<String, dynamic>;
      final msg = body['mesaj'] ?? body['detail'] ?? body['message'];
      if (msg != null && msg.toString().isNotEmpty) {
        return msg.toString();
      }
    } catch (_) {}
    return fallback;
  }
}
