import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/data/qr_vault_biometrics.dart';
import 'package:spekooh/data/qr_vault_pin.dart';
import 'package:spekooh/data/repositories/shop_repository.dart';
import 'package:spekooh/data/token_storage.dart';
import 'package:spekooh/models/pamphlet.dart';
import 'package:spekooh/screens/shop/qr_vault_screen.dart';

import 'support/l10n_test_app.dart';

class _FakeBiometricAuthenticator implements BiometricAuthenticator {
  _FakeBiometricAuthenticator({this.authenticateResult = true});
  final bool authenticateResult;
  int authenticateCalls = 0;

  @override
  Future<bool> isDeviceSupported() async => true;

  @override
  Future<bool> authenticate(String reason) async {
    authenticateCalls++;
    return authenticateResult;
  }
}

class _FakeShopRepository implements ShopRepository {
  _FakeShopRepository(this.orders);
  final List<PamphletOrder> orders;

  @override
  Future<List<PamphletOrder>> getMyOrders() => Future.value(orders);

  @override
  Future<List<Pamphlet>> getPamphlets() => throw UnimplementedError();

  @override
  Future<Pamphlet> getFeaturedPamphlet() => throw UnimplementedError();

  @override
  Future<PamphletOrderResult> placeOrder({
    required int pamphletId,
    required bool isDelivery,
    required String phoneNumber,
    int quantity = 1,
    String deliveryAddress = '',
  }) => throw UnimplementedError();
}

final _order = PamphletOrder(
  id: 7,
  pamphletTitle: 'Probatoire Philosophy Pamphlet',
  status: 'QR_ISSUED',
  amountPaid: 7500,
  createdAt: DateTime(2026, 9, 16),
  qrToken: 'realtoken1234567890',
  qrRedeemUrl: 'https://spekooh-staging.onrender.com/redeem/realtoken1234567890/',
  partnerName: 'Librairie Centrale',
  partnerLocation: 'Avenue Kennedy, Douala',
  partnerPhone: '670000099',
  partnerWhatsapp: '670000098',
);

void main() {
  tearDown(() {
    QrVaultPin.debugSetInstance(QrVaultPin(storage: InMemoryTokenStorage()));
    QrVaultBiometrics.debugSetInstance(QrVaultBiometrics(storage: InMemoryTokenStorage(), authenticator: _FakeBiometricAuthenticator()));
  });

  testWidgets('a first-time visitor must set a PIN before seeing any real ticket data', (tester) async {
    QrVaultPin.debugSetInstance(QrVaultPin(storage: InMemoryTokenStorage()));
    await tester.pumpWidget(l10nTestApp(QrVaultScreen(repository: _FakeShopRepository([_order]))));
    await tester.pump();
    await tester.pump();

    expect(find.text('Set a QR Vault PIN'), findsOneWidget);
    expect(find.text('Probatoire Philosophy Pamphlet'), findsNothing);
    expect(find.text('Librairie Centrale'), findsNothing);
  });

  testWidgets('setting and confirming a PIN reveals the real ticket', (tester) async {
    QrVaultPin.debugSetInstance(QrVaultPin(storage: InMemoryTokenStorage()));
    await tester.pumpWidget(l10nTestApp(QrVaultScreen(repository: _FakeShopRepository([_order]))));
    await tester.pump();
    await tester.pump();

    await tester.enterText(find.byType(TextField), '1234');
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(find.text('Enter the same PIN again to confirm.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '1234');
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pumpAndSettle();

    // The real ticket detail, not just the picker list -- with only one
    // order, QrVaultScreen auto-selects it (a real
    // WidgetsBinding.addPostFrameCallback, hence pumpAndSettle here).
    expect(find.text('Avenue Kennedy, Douala'), findsOneWidget);
    expect(await QrVaultPin.instance.hasPin(), isTrue);
  });

  testWidgets('a returning visitor with the wrong PIN never sees the ticket', (tester) async {
    final storage = InMemoryTokenStorage();
    await QrVaultPin(storage: storage).setPin('4321');
    QrVaultPin.debugSetInstance(QrVaultPin(storage: storage));

    await tester.pumpWidget(l10nTestApp(QrVaultScreen(repository: _FakeShopRepository([_order]))));
    await tester.pump();
    await tester.pump();

    expect(find.text('Enter your QR Vault PIN'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '0000');
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Probatoire Philosophy Pamphlet'), findsNothing);
    expect(find.textContaining('Wrong PIN'), findsOneWidget);
  });

  testWidgets('the correct PIN reveals the real ticket, including bookshop contact info', (tester) async {
    final storage = InMemoryTokenStorage();
    await QrVaultPin(storage: storage).setPin('4321');
    QrVaultPin.debugSetInstance(QrVaultPin(storage: storage));

    await tester.pumpWidget(l10nTestApp(QrVaultScreen(repository: _FakeShopRepository([_order]))));
    await tester.pump();
    await tester.pump();

    await tester.enterText(find.byType(TextField), '4321');
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Probatoire Philosophy Pamphlet'), findsOneWidget);
    expect(find.text('Librairie Centrale'), findsOneWidget);
    expect(find.text('Avenue Kennedy, Douala'), findsOneWidget);
    // Owner-reported bug (2026-09-17): the pickup location wasn't tappable
    // at all -- it must offer a real "View on map" affordance now.
    expect(find.text('View on map'), findsOneWidget);
  });

  testWidgets('the enter-PIN screen has no "Done" button -- only Reset', (tester) async {
    final storage = InMemoryTokenStorage();
    await QrVaultPin(storage: storage).setPin('4321');
    QrVaultPin.debugSetInstance(QrVaultPin(storage: storage));

    await tester.pumpWidget(l10nTestApp(QrVaultScreen(repository: _FakeShopRepository([_order]))));
    await tester.pump();
    await tester.pump();

    expect(find.text('Enter your QR Vault PIN'), findsOneWidget);
    expect(find.text('Done'), findsNothing);
    expect(find.text('Forgot your PIN? Reset it'), findsOneWidget);
  });

  testWidgets('the PIN field refuses more than 4 digits', (tester) async {
    final storage = InMemoryTokenStorage();
    await QrVaultPin(storage: storage).setPin('4321');
    QrVaultPin.debugSetInstance(QrVaultPin(storage: storage));

    await tester.pumpWidget(l10nTestApp(QrVaultScreen(repository: _FakeShopRepository([_order]))));
    await tester.pump();
    await tester.pump();

    await tester.enterText(find.byType(TextField), '432112345');
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text.length, 4);
  });

  testWidgets('resetting the PIN clears it and returns to first-time setup', (tester) async {
    final storage = InMemoryTokenStorage();
    await QrVaultPin(storage: storage).setPin('4321');
    QrVaultPin.debugSetInstance(QrVaultPin(storage: storage));

    await tester.pumpWidget(l10nTestApp(QrVaultScreen(repository: _FakeShopRepository([_order]))));
    await tester.pump();
    await tester.pump();

    expect(find.text('Enter your QR Vault PIN'), findsOneWidget);
    await tester.tap(find.text('Forgot your PIN? Reset it'));
    await tester.pumpAndSettle();

    expect(find.text('Reset your QR Vault PIN?'), findsOneWidget);
    await tester.tap(find.text('Reset PIN'));
    await tester.pumpAndSettle();

    expect(find.text('Set a QR Vault PIN'), findsOneWidget);
    expect(await QrVaultPin.instance.hasPin(), isFalse);
  });

  testWidgets('unlocks automatically via fingerprint when it is already enabled, without needing the PIN', (tester) async {
    final pinStorage = InMemoryTokenStorage();
    await QrVaultPin(storage: pinStorage).setPin('4321');
    QrVaultPin.debugSetInstance(QrVaultPin(storage: pinStorage));

    final bioStorage = InMemoryTokenStorage();
    final authenticator = _FakeBiometricAuthenticator(authenticateResult: true);
    final bio = QrVaultBiometrics(storage: bioStorage, authenticator: authenticator);
    await bio.setEnabled(true);
    await bio.markPrompted(); // already onboarded -- no enrollment offer should fire here
    QrVaultBiometrics.debugSetInstance(bio);

    await tester.pumpWidget(l10nTestApp(QrVaultScreen(repository: _FakeShopRepository([_order]))));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(authenticator.authenticateCalls, 1);
    expect(find.text('Enter your QR Vault PIN'), findsNothing);
    expect(find.text('Probatoire Philosophy Pamphlet'), findsOneWidget);
  });

  testWidgets('falls back to real PIN entry when fingerprint fails, offering a manual retry', (tester) async {
    final pinStorage = InMemoryTokenStorage();
    await QrVaultPin(storage: pinStorage).setPin('4321');
    QrVaultPin.debugSetInstance(QrVaultPin(storage: pinStorage));

    final bioStorage = InMemoryTokenStorage();
    final authenticator = _FakeBiometricAuthenticator(authenticateResult: false);
    final bio = QrVaultBiometrics(storage: bioStorage, authenticator: authenticator);
    await bio.setEnabled(true);
    await bio.markPrompted();
    QrVaultBiometrics.debugSetInstance(bio);

    await tester.pumpWidget(l10nTestApp(QrVaultScreen(repository: _FakeShopRepository([_order]))));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(authenticator.authenticateCalls, 1);
    expect(find.text('Enter your QR Vault PIN'), findsOneWidget);
    expect(find.text('Use fingerprint instead'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '4321');
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Probatoire Philosophy Pamphlet'), findsOneWidget);
  });

  testWidgets('offers fingerprint enrollment once, right after setting up a PIN for the first time', (tester) async {
    QrVaultPin.debugSetInstance(QrVaultPin(storage: InMemoryTokenStorage()));
    final bioStorage = InMemoryTokenStorage();
    final authenticator = _FakeBiometricAuthenticator(authenticateResult: true);
    QrVaultBiometrics.debugSetInstance(QrVaultBiometrics(storage: bioStorage, authenticator: authenticator));

    await tester.pumpWidget(l10nTestApp(QrVaultScreen(repository: _FakeShopRepository([_order]))));
    await tester.pump();
    await tester.pump();

    await tester.enterText(find.byType(TextField), '1234');
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '1234');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Use fingerprint to unlock?'), findsOneWidget);
    await tester.tap(find.text('Enable'));
    await tester.pumpAndSettle();

    expect(await QrVaultBiometrics.instance.isEnabled(), isTrue);
    expect(await QrVaultBiometrics.instance.hasBeenPrompted(), isTrue);
  });

  testWidgets('declining the fingerprint offer never enables it, and never asks again', (tester) async {
    QrVaultPin.debugSetInstance(QrVaultPin(storage: InMemoryTokenStorage()));
    final bioStorage = InMemoryTokenStorage();
    QrVaultBiometrics.debugSetInstance(QrVaultBiometrics(storage: bioStorage, authenticator: _FakeBiometricAuthenticator()));

    await tester.pumpWidget(l10nTestApp(QrVaultScreen(repository: _FakeShopRepository([_order]))));
    await tester.pump();
    await tester.pump();

    await tester.enterText(find.byType(TextField), '1234');
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '1234');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(await QrVaultBiometrics.instance.isEnabled(), isFalse);
    expect(await QrVaultBiometrics.instance.hasBeenPrompted(), isTrue);
  });
}
