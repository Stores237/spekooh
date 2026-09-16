import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/data/qr_vault_pin.dart';
import 'package:spekooh/data/token_storage.dart';

void main() {
  group('QrVaultPin', () {
    late InMemoryTokenStorage storage;
    late QrVaultPin pin;

    setUp(() {
      storage = InMemoryTokenStorage();
      pin = QrVaultPin(storage: storage);
    });

    test('has no PIN until one is set', () async {
      expect(await pin.hasPin(), isFalse);
      await pin.setPin('1234');
      expect(await pin.hasPin(), isTrue);
    });

    test('never stores the PIN in plaintext', () async {
      await pin.setPin('1234');
      final rawValues = await Future.wait([storage.read('qr_vault_pin_hash'), storage.read('qr_vault_pin_salt')]);
      for (final value in rawValues) {
        expect(value, isNotNull);
        expect(value, isNot(contains('1234')));
      }
    });

    test('a correct PIN verifies successfully', () async {
      await pin.setPin('4321');
      expect(await pin.verifyPin('4321'), QrVaultPinResult.success);
    });

    test('the same PIN produces a different stored hash each time (real random salt)', () async {
      final storageA = InMemoryTokenStorage();
      final storageB = InMemoryTokenStorage();
      await QrVaultPin(storage: storageA).setPin('1111');
      await QrVaultPin(storage: storageB).setPin('1111');

      final saltA = await storageA.read('qr_vault_pin_salt');
      final saltB = await storageB.read('qr_vault_pin_salt');
      final hashA = await storageA.read('qr_vault_pin_hash');
      final hashB = await storageB.read('qr_vault_pin_hash');

      expect(saltA, isNot(saltB));
      expect(hashA, isNot(hashB));
    });

    test('a wrong PIN fails without locking out before the attempt cap', () async {
      await pin.setPin('4321');
      for (var i = 0; i < QrVaultPin.maxAttempts - 1; i++) {
        expect(await pin.verifyPin('0000'), QrVaultPinResult.wrongPin);
      }
      expect(await pin.lockedOutForSeconds(), isNull);
    });

    test('hitting the attempt cap locks the vault out, independent of anything else', () async {
      await pin.setPin('4321');
      for (var i = 0; i < QrVaultPin.maxAttempts; i++) {
        await pin.verifyPin('0000');
      }
      expect(await pin.lockedOutForSeconds(), isNotNull);
      expect(await pin.lockedOutForSeconds(), greaterThan(0));

      // Even the *correct* PIN is refused while locked out -- the cap is a
      // real gate, not just a delay before the next guess.
      expect(await pin.verifyPin('4321'), QrVaultPinResult.lockedOut);
    });

    test('a correct verification resets the attempt counter', () async {
      await pin.setPin('4321');
      await pin.verifyPin('0000');
      await pin.verifyPin('0000');
      expect(await pin.attemptsRemaining(), QrVaultPin.maxAttempts - 2);

      await pin.verifyPin('4321');
      expect(await pin.attemptsRemaining(), QrVaultPin.maxAttempts);
    });

    test('setting a new PIN clears any prior lockout', () async {
      await pin.setPin('4321');
      for (var i = 0; i < QrVaultPin.maxAttempts; i++) {
        await pin.verifyPin('0000');
      }
      expect(await pin.lockedOutForSeconds(), isNotNull);

      await pin.setPin('9999');
      expect(await pin.lockedOutForSeconds(), isNull);
      expect(await pin.verifyPin('9999'), QrVaultPinResult.success);
    });
  });
}
