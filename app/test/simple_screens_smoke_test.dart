import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/data/repositories/forum_repository.dart';
import 'package:spekooh/data/repositories/notifications_repository.dart';
import 'package:spekooh/data/repositories/profile_repository.dart';
import 'package:spekooh/data/repositories/shop_repository.dart';
import 'package:spekooh/models/pamphlet.dart';
import 'package:spekooh/models/spekooh_user.dart';
import 'package:spekooh/screens/forum/forum_screen.dart';
import 'package:spekooh/screens/shop/shop_screen.dart';
import 'package:spekooh/screens/notifications/notifications_screen.dart';
import 'package:spekooh/screens/settings/settings_screen.dart';
import 'package:spekooh/screens/profile/profile_screen.dart';
import 'package:spekooh/theme/app_theme.dart';

Future<void> _pumpAndCheck(WidgetTester tester, Widget screen) async {
  await tester.pumpWidget(MaterialApp(theme: appTheme, home: screen));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50)); // let FutureBuilder futures resolve
  expect(tester.takeException(), isNull);
}

void main() {
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
    await _pumpAndCheck(tester, const SettingsScreen());
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
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
    await _pumpAndCheck(tester, ProfileScreen(repository: MockProfileRepository()));
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Redeem code ready'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget); // real tappable share action, not dead text
  });

  testWidgets('ProfileScreen shows an honest state when there is no active redeem code', (tester) async {
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
}
