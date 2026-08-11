import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'token_storage.dart';

/// Base URL for the auth endpoints specifically, since [AuthSession] can't
/// depend on [ApiClient] (ApiClient depends on AuthSession for its bearer
/// token) — kept in sync with api_client.dart's default/override.
const String _authBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8000/api');

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Persists JWT tokens in secure storage and exposes login/register/logout.
/// A [ChangeNotifier] so RootShell can listen for login-state changes.
class AuthSession extends ChangeNotifier {
  AuthSession({TokenStorage? storage, http.Client? httpClient})
      : _storage = storage ?? const SecureTokenStorage(),
        _client = httpClient ?? http.Client();

  /// Swappable in tests via [debugSetInstance] — flutter_secure_storage's
  /// platform channel isn't available under `flutter test`.
  static AuthSession instance = AuthSession();

  @visibleForTesting
  static void debugSetInstance(AuthSession session) => instance = session;

  final TokenStorage _storage;
  final http.Client _client;

  static const _accessKey = 'spekooh_access_token';
  static const _refreshKey = 'spekooh_refresh_token';
  static const _userIdKey = 'spekooh_user_id';

  String? accessToken;
  String? refreshToken;
  String? currentUserId;

  bool get isLoggedIn => accessToken != null;

  /// Reads persisted tokens on app start so a login survives a restart.
  Future<void> bootstrap() async {
    accessToken = await _storage.read(_accessKey);
    refreshToken = await _storage.read(_refreshKey);
    currentUserId = await _storage.read(_userIdKey);
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    final response = await _client.post(
      Uri.parse('$_authBaseUrl/auth/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode != 200) {
      throw AuthException('Login failed. Check your email and password.');
    }
    await _storeTokens(jsonDecode(response.body));
  }

  Future<void> register({required String email, required String name, required String password}) async {
    final response = await _client.post(
      Uri.parse('$_authBaseUrl/auth/register/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'name': name, 'password': password}),
    );
    if (response.statusCode != 201) {
      throw AuthException('Registration failed. That email may already be in use.');
    }
    await _storeTokens(jsonDecode(response.body));
  }

  Future<void> _storeTokens(Map<String, dynamic> data) async {
    accessToken = data['access'] as String;
    refreshToken = data['refresh'] as String;
    currentUserId = (data['user'] as Map<String, dynamic>)['id'] as String;
    await _storage.write(_accessKey, accessToken!);
    await _storage.write(_refreshKey, refreshToken!);
    await _storage.write(_userIdKey, currentUserId!);
    notifyListeners();
  }

  /// Attempts a silent refresh using the stored refresh token. Returns
  /// whether it succeeded — on failure, [ApiClient] surfaces the original 401.
  Future<bool> refreshAccessToken() async {
    final refresh = refreshToken;
    if (refresh == null) return false;
    try {
      final response = await _client.post(
        Uri.parse('$_authBaseUrl/auth/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refresh}),
      );
      if (response.statusCode != 200) return false;
      accessToken = (jsonDecode(response.body) as Map<String, dynamic>)['access'] as String;
      await _storage.write(_accessKey, accessToken!);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    accessToken = null;
    refreshToken = null;
    currentUserId = null;
    await _storage.delete(_accessKey);
    await _storage.delete(_refreshKey);
    await _storage.delete(_userIdKey);
    notifyListeners();
  }
}
