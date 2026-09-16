import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import 'token_storage.dart';

enum QrVaultPinResult { success, wrongPin, lockedOut }

/// Local app-lock for QR Vault (owner request, 2026-09-16: "the page have to
/// access only with a 4 digit code the user will set and confirm"). This
/// gates a screen, not an account -- it's enforced entirely on-device, with
/// no server round trip, so the security properties that matter are the
/// ones SECURITY.md already asks of every credential in this app:
///
/// - Never stored in plaintext (SECURITY.md "Secrets management") -- only a
///   salted SHA-256 hash is persisted, in the same flutter_secure_storage
///   backing AuthSession already uses for real auth tokens, never in
///   SharedPreferences/plaintext.
/// - Brute-force bounded independently of anything else (SECURITY.md
///   "Authentication": "the reset code itself also has its own attempt
///   cap... bounded independently of the request-rate throttle") -- a
///   4-digit PIN is only 10,000 combinations, so this matters far more here
///   than for a real password: 5 wrong attempts locks the vault for 5
///   minutes, not just a generic rate limit elsewhere.
class QrVaultPin {
  QrVaultPin({TokenStorage? storage}) : _storage = storage ?? const SecureTokenStorage();

  static QrVaultPin instance = QrVaultPin();

  @visibleForTesting
  static void debugSetInstance(QrVaultPin pin) => instance = pin;

  static const _hashKey = 'qr_vault_pin_hash';
  static const _saltKey = 'qr_vault_pin_salt';
  static const _attemptsKey = 'qr_vault_pin_attempts';
  static const _lockedUntilKey = 'qr_vault_pin_locked_until';

  static const maxAttempts = 5;
  static const lockoutDuration = Duration(minutes: 5);

  final TokenStorage _storage;

  Future<bool> hasPin() async => (await _storage.read(_hashKey)) != null;

  Future<void> setPin(String pin) async {
    final salt = _generateSalt();
    await _storage.write(_saltKey, salt);
    await _storage.write(_hashKey, _hash(pin, salt));
    await _storage.delete(_attemptsKey);
    await _storage.delete(_lockedUntilKey);
  }

  /// Seconds remaining in a lockout, or null if not currently locked out.
  Future<int?> lockedOutForSeconds() async {
    final lockedUntilRaw = await _storage.read(_lockedUntilKey);
    if (lockedUntilRaw == null) return null;
    final lockedUntil = DateTime.tryParse(lockedUntilRaw);
    if (lockedUntil == null) return null;
    final remaining = lockedUntil.difference(DateTime.now());
    if (remaining.isNegative) {
      // Lockout has elapsed -- clear it so the next attempt is a real one,
      // not silently treated as still-locked forever.
      await _storage.delete(_lockedUntilKey);
      await _storage.delete(_attemptsKey);
      return null;
    }
    return remaining.inSeconds;
  }

  Future<QrVaultPinResult> verifyPin(String pin) async {
    final lockedSeconds = await lockedOutForSeconds();
    if (lockedSeconds != null) return QrVaultPinResult.lockedOut;

    final salt = await _storage.read(_saltKey);
    final storedHash = await _storage.read(_hashKey);
    if (salt == null || storedHash == null) return QrVaultPinResult.wrongPin;

    if (_hash(pin, salt) == storedHash) {
      await _storage.delete(_attemptsKey);
      return QrVaultPinResult.success;
    }

    final attempts = (int.tryParse(await _storage.read(_attemptsKey) ?? '0') ?? 0) + 1;
    if (attempts >= maxAttempts) {
      await _storage.write(_lockedUntilKey, DateTime.now().add(lockoutDuration).toIso8601String());
      await _storage.delete(_attemptsKey);
    } else {
      await _storage.write(_attemptsKey, attempts.toString());
    }
    return QrVaultPinResult.wrongPin;
  }

  Future<int> attemptsRemaining() async {
    final attempts = int.tryParse(await _storage.read(_attemptsKey) ?? '0') ?? 0;
    return max(0, maxAttempts - attempts);
  }

  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }

  String _hash(String pin, String salt) => sha256.convert(utf8.encode('$salt:$pin')).toString();
}
