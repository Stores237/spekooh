import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/data/auth_session.dart';
import 'package:spekooh/data/repositories/forum_repository.dart';
import 'package:spekooh/data/repositories/notifications_repository.dart';
import 'package:spekooh/data/repositories/profile_repository.dart';
import 'package:spekooh/data/repositories/shop_repository.dart';
import 'package:spekooh/data/token_storage.dart';
import 'package:spekooh/models/pamphlet.dart';
import 'package:spekooh/models/spekooh_user.dart';
import 'package:spekooh/screens/forum/forum_screen.dart';
import 'package:spekooh/screens/shop/shop_screen.dart';
import 'package:spekooh/screens/notifications/notifications_screen.dart';
import 'package:spekooh/screens/settings/settings_screen.dart';
import 'package:spekooh/screens/profile/profile_screen.dart';

import 'support/l10n_test_app.dart';

Future<void> _pumpAndCheck(WidgetTester tester, Widget screen) async {
  await tester.pumpWidget(l10nTestApp(screen));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50)); // let FutureBuilder futures resolve
  expect(tester.takeException(), isNull);
}

/// ProfileScreen (and anything else auth-gated) checks AuthSession.instance
/// directly rather than taking a repository-level "am I logged in" flag —
/// this simulates an already-logged-in session without a network call.
void _fakeLoggedIn() {
  final session = AuthSession(storage: InMemoryTokenStorage());
  session.accessToken = 'fake-access-token';
  AuthSession.debugSetInstance(session);
}

void main() {
  tearDown(() {
    // AuthSession.instance is a global singleton — reset it so a test that
    // fakes a login doesn't leak into the next test in this file.
    AuthSession.debugSetInstance(AuthSession(storage: InMemoryTokenStorage()));
  });

  testWidgets('ForumScreen builds with no exceptions', (tester) async {
    await _pumpAndCheck(tester, ForumScreen(repository: MockForumRepository()));
    expect(find.text('Forum'), findsOneWidget);
    expect(find.text('Rescheduling of Baccalauréat 2026'), findsOneWidget);
  });

  testWidgets('ShopScreen builds with no exceptions', (tester) async {
    await _pumpAndCheck(tester, ShopScreen(repository: MockShopRepository()));
    expect(find.text('Shop'), findsOneWidget);
    expect(find.text('Probatoire Philosophy Pamphlet'), findsOneWidget);
  });

  testWidgets('ShopScreen search filters the real pamphlet list', (tester) async {
    await _pumpAndCheck(tester, ShopScreen(repository: MockShopRepository()));
    expect(find.text('GCE A Level Further Maths Pack'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Philosophy');
    await tester.pump();
    expect(find.text('Probatoire Philosophy Pamphlet'), findsOneWidget);
    expect(find.text('GCE A Level Further Maths Pack'), findsNothing);
  });

  testWidgets('ShopScreen tapping a specific pamphlet passes that exact pamphlet, not always the featured one', (tester) async {
    Pamphlet? opened;
    await _pumpAndCheck(tester, ShopScreen(repository: MockShopRepository(), onOpenPamphlet: (p) => opened = p));
    await tester.ensureVisible(find.text('GCE A Level Further Maths Pack'));
    await tester.pump();
    await tester.tap(find.text('GCE A Level Further Maths Pack'));
    await tester.pump();
    expect(opened?.title, 'GCE A Level Further Maths Pack');
  });

  testWidgets('NotificationsScreen builds with no exceptions', (tester) async {
    await _pumpAndCheck(tester, NotificationsScreen(repository: MockNotificationsRepository()));
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.textContaining('Welcome to Spekooh'), findsOneWidget);
  });

  testWidgets('SettingsScreen builds with no exceptions', (tester) async {
    await _pumpAndCheck(tester, SettingsScreen(profileRepository: MockProfileRepository()));
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
  });

  testWidgets('SettingsScreen shows a real Log out button once actually logged in, not still "Log in"', (tester) async {
    _fakeLoggedIn();
    var loggedOut = false;
    await _pumpAndCheck(tester, SettingsScreen(onLogout: () => loggedOut = true));
    expect(find.text('Log out'), findsOneWidget);
    expect(find.text('Log in'), findsNothing);
    await tester.ensureVisible(find.text('Log out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out'));
    expect(loggedOut, isTrue);
  });

  testWidgets('SettingsScreen Log in button calls onLogin', (tester) async {
    var called = false;
    await _pumpAndCheck(tester, SettingsScreen(onLogin: () => called = true));
    await tester.ensureVisible(find.text('Log in'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log in'));
    expect(called, isTrue);
  });

  testWidgets('SettingsScreen Spekooh Pro card opens the real paywall', (tester) async {
    var opened = false;
    await _pumpAndCheck(tester, SettingsScreen(onOpenPaywall: () => opened = true));
    await tester.tap(find.text('Spekooh Pro'));
    expect(opened, isTrue);
  });

  testWidgets('ProfileScreen builds with no exceptions', (tester) async {
    _fakeLoggedIn();
    await _pumpAndCheck(tester, ProfileScreen(repository: MockProfileRepository()));
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Redeem code ready'), findsOneWidget);
    expect(find.text('Invite a friend'), findsOneWidget);
    // Two real, independently-tappable share actions (redeem code + referral code), not dead text.
    expect(find.text('Share'), findsNWidgets(2));
  });

  testWidgets('ProfileScreen shows an honest state when there is no active redeem code', (tester) async {
    _fakeLoggedIn();
    const user = SpekoohUser(
      name: 'Guest',
      joinDate: 'Joined Jul 2026',
      submissionsCount: 0,
      quizzesCount: 0,
      creditBalance: 0,
      redeemCode: '',
      redeemCodeSubtitle: '',
    );
    await _pumpAndCheck(tester, ProfileScreen(repository: MockProfileRepository(user: user)));
    expect(find.text('No active redeem code'), findsOneWidget);
    expect(find.text('Redeem code ready'), findsNothing);
    expect(find.text('Share'), findsNothing); // nothing real to share
  });

  testWidgets('ProfileScreen shows an honest log-in prompt for a guest instead of a blank/broken page', (tester) async {
    AuthSession.debugSetInstance(AuthSession(storage: InMemoryTokenStorage())); // logged out
    var loginTapped = false;
    await _pumpAndCheck(tester, ProfileScreen(repository: MockProfileRepository(), onLogin: () => loginTapped = true));
    expect(find.text('Log in to see your profile'), findsOneWidget);
    expect(find.text('Redeem code ready'), findsNothing); // no account data shown for a guest
    await tester.tap(find.text('Log in'));
    expect(loginTapped, isTrue);
  });
}
