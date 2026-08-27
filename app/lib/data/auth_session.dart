import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'locale_controller.dart';
import 'token_storage.dart';

/// Base URL for the auth endpoints specifically, since [AuthSession] can't
/// depend on [ApiClient] (ApiClient depends on AuthSession for its bearer
/// token) — kept in sync with api_client.dart's default/override, including
/// the kIsWeb split (10.0.2.2 resolves to nothing on web).
const String _authDefaultBaseUrl = kIsWeb ? 'http://localhost:8000/api' : 'http://10.0.2.2:8000/api';
const String _authBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: _authDefaultBaseUrl);

/// Which of AuthSession's fixed set of failures happened — the widget layer
/// (which has a BuildContext, so can reach AppLocalizations) maps this to a
/// real localized message rather than AuthSession carrying pre-built,
/// English-only text.
enum AuthErrorCode {
  loginFailed,
  loginFailedEmailNotVerified,
  registerFailedReferral,
  registerFailedGeneric,
  registerFailedInvalidEmailDomain,
  guestFailed,
  passwordResetRequestFailed,
  passwordResetConfirmFailed,
  emailVerificationConfirmFailed,
  emailVerificationResendFailed,
}

class AuthException implements Exception {
  AuthException(this.code, this.debugMessage);
  final AuthErrorCode code;

  /// English, for logs/debugging only — never shown to the user directly.
  final String debugMessage;

  @override
  String toString() => debugMessage;
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
      // EmailTokenObtainPairSerializer reports the REQUIRE_EMAIL_VERIFICATION
      // gate as {"code": ["email_not_verified"]} — a stable machine-readable
      // signal, distinct from a plain wrong-password rejection, so the UI
      // can offer a real recovery path instead of a dead-end generic error.
      Map<String, dynamic>? body;
      try {
        body = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        // Non-JSON error body — fall through to the generic message below.
      }
      final code = body?['code'];
      if (code is List && code.contains('email_not_verified')) {
        throw AuthException(AuthErrorCode.loginFailedEmailNotVerified, 'Please verify your email before logging in.');
      }
      throw AuthException(AuthErrorCode.loginFailed, 'Login failed. Check your email and password.');
    }
    await _storeTokens(jsonDecode(response.body));
  }

  /// Returns whether the new account still needs email verification (i.e.
  /// the caller should follow up with [confirmEmailVerification]) — the
  /// backend already issued+sent a real code as part of this same request
  /// (RegisterView), so this is never a separate round trip.
  Future<bool> register({
    required String email,
    required String name,
    required String password,
    required bool termsAccepted,
    String? referralCode,
  }) async {
    final response = await _client.post(
      Uri.parse('$_authBaseUrl/auth/register/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'name': name,
        'password': password,
        'terms_accepted': termsAccepted,
        if (referralCode != null && referralCode.isNotEmpty) 'referral_code': referralCode,
      }),
    );
    if (response.statusCode != 201) {
      // RegisterSerializer.validate_email (the verify-email-domain edge
      // function check) reports its rejection as a field error on "email"
      // — surface that specifically, since "that email may already be in
      // use" would be actively wrong advice for a typo'd domain.
      Map<String, dynamic>? body;
      try {
        body = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        // Non-JSON error body — fall through to the generic message below.
      }
      if (body?['email'] != null) {
        throw AuthException(
          AuthErrorCode.registerFailedInvalidEmailDomain,
          "Registration failed. That email domain doesn't appear to accept mail.",
        );
      }
      if (referralCode != null && referralCode.isNotEmpty) {
        throw AuthException(
          AuthErrorCode.registerFailedReferral,
          "Registration failed. Check your details, and that the referral code is correct.",
        );
      }
      throw AuthException(AuthErrorCode.registerFailedGeneric, 'Registration failed. That email may already be in use.');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    await _storeTokens(data);
    final user = data['user'] as Map<String, dynamic>;
    return user['email_verified'] != true;
  }

  /// Owner decision: contributing (Submit) shouldn't require a real
  /// account, but every contributor still has to be identified by a real
  /// name they typed. This is deliberately NOT a login: it mints a real
  /// guest User row on the backend (so the submission has a real owner
  /// and the contributor bonus has somewhere to land) but returns the raw
  /// access token to the caller instead of storing it on this session —
  /// [isLoggedIn], [accessToken], and secure-storage persistence are all
  /// untouched. The token exists only for whatever single request the
  /// caller passes it to (see PapersRepository.submitPaper's
  /// guestAccessToken param); nothing about this guest identity survives
  /// the app closing, and every other action in the app still requires a
  /// real account. Each call mints a fresh, separate guest — there's
  /// nothing to reuse across calls by design.
  Future<String> mintGuestAccessToken({required String name}) async {
    final response = await _client.post(
      Uri.parse('$_authBaseUrl/auth/guest/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name}),
    );
    if (response.statusCode != 201) {
      throw AuthException(AuthErrorCode.guestFailed, 'Could not continue as guest.');
    }
    return (jsonDecode(response.body) as Map<String, dynamic>)['access'] as String;
  }

  /// Always a 200 from the backend regardless of whether [email] matches a
  /// real account (see PasswordResetRequestSerializer) — this only throws
  /// on a genuine network/server failure (or the rate limit), never on "no
  /// such account", so the UI can't be used to probe which emails exist.
  Future<void> requestPasswordReset({required String email}) async {
    final response = await _client.post(
      Uri.parse('$_authBaseUrl/auth/password-reset/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode != 200) {
      throw AuthException(AuthErrorCode.passwordResetRequestFailed, 'Could not request a password reset code.');
    }
  }

  /// Not a login — doesn't touch [accessToken]/[isLoggedIn]. The caller
  /// (PasswordResetSheet) sends the user to the login form afterward.
  Future<void> confirmPasswordReset({required String email, required String code, required String newPassword}) async {
    final response = await _client.post(
      Uri.parse('$_authBaseUrl/auth/password-reset/confirm/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code, 'new_password': newPassword}),
    );
    if (response.statusCode != 200) {
      throw AuthException(AuthErrorCode.passwordResetConfirmFailed, 'That code is invalid or has expired.');
    }
  }

  /// Confirms the code RegisterView already sent at signup. Authenticated
  /// (unlike password reset, this always runs from an already-logged-in
  /// session — registration itself grants tokens).
  Future<void> confirmEmailVerification({required String code}) async {
    final response = await _client.post(
      Uri.parse('$_authBaseUrl/auth/verify-email/'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken'},
      body: jsonEncode({'code': code}),
    );
    if (response.statusCode != 200) {
      throw AuthException(AuthErrorCode.emailVerificationConfirmFailed, 'That code is invalid or has expired.');
    }
  }

  Future<void> resendEmailVerification() async {
    final response = await _client.post(
      Uri.parse('$_authBaseUrl/auth/verify-email/resend/'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken'},
    );
    if (response.statusCode != 200) {
      throw AuthException(AuthErrorCode.emailVerificationResendFailed, 'Could not resend a verification code.');
    }
  }

  /// Recovery path for a registered account stranded by
  /// REQUIRE_EMAIL_VERIFICATION: no session to call [resendEmailVerification]
  /// with (the original in-session code from signup is long gone), so this
  /// requests a fresh one by email instead — same non-revealing shape as
  /// [requestPasswordReset] (always succeeds from the caller's point of
  /// view). Used from AuthSheet's login-failure recovery, not registration.
  Future<void> requestEmailVerificationByEmail({required String email}) async {
    final response = await _client.post(
      Uri.parse('$_authBaseUrl/auth/verify-email/request-by-email/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode != 200) {
      throw AuthException(AuthErrorCode.emailVerificationResendFailed, 'Could not resend a verification code.');
    }
  }

  /// Confirms the code from [requestEmailVerificationByEmail] — does NOT
  /// log the caller in (unlike registration's flow, there's no session
  /// here to grant tokens into). The caller logs in for real afterward
  /// with their password.
  Future<void> confirmEmailVerificationByEmail({required String email, required String code}) async {
    final response = await _client.post(
      Uri.parse('$_authBaseUrl/auth/verify-email/confirm-by-email/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    );
    if (response.statusCode != 200) {
      throw AuthException(AuthErrorCode.emailVerificationConfirmFailed, 'That code is invalid or has expired.');
    }
  }

  Future<void> _storeTokens(Map<String, dynamic> data) async {
    accessToken = data['access'] as String;
    refreshToken = data['refresh'] as String;
    final user = data['user'] as Map<String, dynamic>;
    currentUserId = user['id'] as String;
    await _storage.write(_accessKey, accessToken!);
    await _storage.write(_refreshKey, refreshToken!);
    await _storage.write(_userIdKey, currentUserId!);
    // The account's own language_pref wins over this device's system
    // default the first time we learn it — but not over a choice this
    // device already made explicitly (see LocaleController.syncFromAccount).
    await LocaleController.instance.syncFromAccount(user['language_pref'] as String?);
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
