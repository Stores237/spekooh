import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/data/auth_session.dart';
import 'package:spekooh/data/locale_controller.dart';
import 'package:spekooh/data/repositories/profile_repository.dart';
import 'package:spekooh/data/token_storage.dart';
import 'package:spekooh/screens/settings/settings_screen.dart';

import 'support/l10n_test_app.dart';

class _RecordingProfileRepository extends MockProfileRepository {
  final calls = <String>[];

  @override
  Future<void> setLanguagePreference(String code) async {
    calls.add(code);
  }
}

void main() {
  setUp(() {
    LocaleController.debugSetInstance(LocaleController(storage: InMemoryTokenStorage()));
  });

  testWidgets('SettingsScreen renders in French once that locale is active', (tester) async {
    await LocaleController.instance.setLocale('fr');
    await tester.pumpWidget(l10nTestApp(SettingsScreen(profileRepository: MockProfileRepository())));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Paramètres'), findsOneWidget);
    expect(find.text('LANGUE'), findsOneWidget); // _sectionLabel uppercases it
    expect(find.text('Settings'), findsNothing);
  });

  testWidgets('tapping Français switches the whole screen to French live, guest (no backend sync)', (tester) async {
    final repo = _RecordingProfileRepository();
    await tester.pumpWidget(l10nTestApp(SettingsScreen(profileRepository: repo)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Settings'), findsOneWidget);
    await tester.tap(find.text('Français'));
    await tester.pumpAndSettle();

    expect(find.text('Paramètres'), findsOneWidget);
    expect(find.text('Settings'), findsNothing);
    expect(repo.calls, isEmpty); // guest — nothing to sync to an account
  });

  testWidgets('tapping Français while logged in also syncs the account language_pref', (tester) async {
    final session = AuthSession(storage: InMemoryTokenStorage());
    session.accessToken = 'fake-token';
    AuthSession.debugSetInstance(session);
    final repo = _RecordingProfileRepository();

    await tester.pumpWidget(l10nTestApp(SettingsScreen(profileRepository: repo)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('Français'));
    await tester.pumpAndSettle();

    expect(repo.calls, ['fr']);
  });
}
