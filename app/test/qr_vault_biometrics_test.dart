import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/data/qr_vault_biometrics.dart';
import 'package:spekooh/data/token_storage.dart';

class _FakeBiometricAuthenticator implements BiometricAuthenticator {
  _FakeBiometricAuthenticator({this.supported = true, this.authenticateResult = true});
  bool supported;
  bool authenticateResult;
  int authenticateCalls = 0;
  String? lastReason;

  @override
  Future<bool> isDeviceSupported() async => supported;

  @override
  Future<bool> authenticate(String reason) async {
    authenticateCalls++;
    lastReason = reason;
    return authenticateResult;
  }
}

void main() {
  group('QrVaultBiometrics', () {
    late InMemoryTokenStorage storage;
    late _FakeBiometricAuthenticator authenticator;
    late QrVaultBiometrics biometrics;

    setUp(() {
      storage = InMemoryTokenStorage();
      authenticator = _FakeBiometricAuthenticator();
      biometrics = QrVaultBiometrics(storage: storage, authenticator: authenticator);
    });

    test('is disabled and not prompted by default', () async {
      expect(await biometrics.isEnabled(), isFalse);
      expect(await biometrics.hasBeenPrompted(), isFalse);
    });

    test('setEnabled persists across a fresh instance reading the same storage', () async {
      await biometrics.setEnabled(true);
      expect(await biometrics.isEnabled(), isTrue);

      final freshRead = QrVaultBiometrics(storage: storage, authenticator: authenticator);
      expect(await freshRead.isEnabled(), isTrue);
    });

    test('markPrompted persists so the enrollment offer is never shown twice', () async {
      expect(await biometrics.hasBeenPrompted(), isFalse);
      await biometrics.markPrompted();
      expect(await biometrics.hasBeenPrompted(), isTrue);
    });

    test('isDeviceSupported delegates to the injected authenticator', () async {
      final unsupported = QrVaultBiometrics(storage: storage, authenticator: _FakeBiometricAuthenticator(supported: false));
      expect(await unsupported.isDeviceSupported(), isFalse);
      expect(await biometrics.isDeviceSupported(), isTrue);
    });

    test('authenticate passes the real localized reason through and returns the real result', () async {
      expect(await biometrics.authenticate('Unlock your QR Vault'), isTrue);
      expect(authenticator.lastReason, 'Unlock your QR Vault');
      expect(authenticator.authenticateCalls, 1);

      final refusing = QrVaultBiometrics(storage: storage, authenticator: _FakeBiometricAuthenticator(authenticateResult: false));
      expect(await refusing.authenticate('Unlock your QR Vault'), isFalse);
    });
  });
}
