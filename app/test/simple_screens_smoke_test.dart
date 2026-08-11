import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/data/repositories/forum_repository.dart';
import 'package:spekooh/data/repositories/notifications_repository.dart';
import 'package:spekooh/data/repositories/profile_repository.dart';
import 'package:spekooh/data/repositories/shop_repository.dart';
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

  testWidgets('ProfileScreen builds with no exceptions', (tester) async {
    await _pumpAndCheck(tester, ProfileScreen(repository: MockProfileRepository()));
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Redeem code ready'), findsOneWidget);
  });
}
