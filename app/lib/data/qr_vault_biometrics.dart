import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

import 'token_storage.dart';

/// Thin seam over [LocalAuthentication] (owner request, 2026-09-17: "unlock
/// with fingerprint") -- a widget test can't touch local_auth's platform
/// channel, so QrVaultBiometrics depends on this interface rather than the
/// concrete class directly, the same seam pattern TokenStorage already uses
/// for flutter_secure_storage.
abstract class BiometricAuthenticator {
  Future<bool> isDeviceSupported();
  Future<bool> authenticate(String reason);
}

class RealBiometricAuthenticator implements BiometricAuthenticator {
  final _auth = LocalAuthentication();

  @override
  Future<bool> isDeviceSupported() async {
    try {
      if (!await _auth.isDeviceSupported()) return false;
      final available = await _auth.getAvailableBiometrics();
      return available.isNotEmpty;
    } on Exception {
      // A device with no biometric hardware, or one where the platform
      // plugin isn't wired up correctly, should fall back to PIN-only
      // rather than crash the whole unlock screen.
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } on Exception {
      return false;
    }
  }
}

/// QR Vault's optional fingerprint/Face ID unlock, layered on top of the
/// real 4-digit PIN (QrVaultPin) rather than replacing it -- the PIN stays
/// the actual credential; a successful biometric match is just treated as
/// equivalent to a correct PIN entry, the same trust model banking apps use
/// for "quick unlock" while keeping a PIN/password as the real fallback.
/// Opt-in only: never auto-enabled, and the device's own biometric
/// enrollment (fingerprint/face already set up in Settings) is what
/// authenticate() actually checks against -- nothing here stores or
/// compares biometric data itself.
class QrVaultBiometrics {
  QrVaultBiometrics({TokenStorage? storage, BiometricAuthenticator? authenticator})
      : _storage = storage ?? const SecureTokenStorage(),
        _authenticator = authenticator ?? RealBiometricAuthenticator();

  static QrVaultBiometrics instance = QrVaultBiometrics();

  @visibleForTesting
  static void debugSetInstance(QrVaultBiometrics biometrics) => instance = biometrics;

  static const _enabledKey = 'qr_vault_biometric_enabled';
  static const _promptedKey = 'qr_vault_biometric_prompted';

  final TokenStorage _storage;
  final BiometricAuthenticator _authenticator;

  Future<bool> isDeviceSupported() => _authenticator.isDeviceSupported();

  Future<bool> isEnabled() async => (await _storage.read(_enabledKey)) == 'true';

  Future<void> setEnabled(bool enabled) => _storage.write(_enabledKey, enabled.toString());

  /// Whether the user has already been offered biometric unlock once --
  /// gates the one-time enrollment prompt so it doesn't nag on every visit.
  Future<bool> hasBeenPrompted() async => (await _storage.read(_promptedKey)) != null;

  Future<void> markPrompted() => _storage.write(_promptedKey, 'true');

  Future<bool> authenticate(String reason) => _authenticator.authenticate(reason);
}
