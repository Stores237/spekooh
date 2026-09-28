// The prompt shown when the server says this account still has to accept the
// current Terms of Service. Blocking by design: the only ways out are to
// accept (after an explicit tick) or to log out.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/data/locale_controller.dart';
import 'package:spekooh/data/repositories/profile_repository.dart';
import 'package:spekooh/data/token_storage.dart';
import 'package:spekooh/screens/legal/terms_of_service_screen.dart';
import 'package:spekooh/sheets/terms_update_dialog.dart';
import 'package:spekooh/widgets/spekooh_button.dart';

import 'support/l10n_test_app.dart';

/// Throws on the first accept, succeeds afterwards.
class _FlakyProfileRepository extends MockProfileRepository {
  bool failNext = true;

  @override
  Future<void> acceptTerms(String version) async {
    if (failNext) {
      failNext = false;
      throw Exception('offline');
    }
    return super.acceptTerms(version);
  }
}

Future<void> _open(WidgetTester tester, ProfileRepository repository, {Future<void> Function()? onLogout}) async {
  await tester.pumpWidget(l10nTestApp(
    Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (_) => TermsUpdateDialog(version: '2099-01-01', repository: repository, onLogout: onLogout ?? () async {}),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

SpekoohButton _acceptButton(WidgetTester tester) => tester.widget<SpekoohButton>(find.byType(SpekoohButton));

void main() {
  tearDown(() {
    LocaleController.debugSetInstance(LocaleController(storage: InMemoryTokenStorage()));
  });

  testWidgets('explains the change and cannot be accepted until the box is ticked', (tester) async {
    await _open(tester, MockProfileRepository());

    expect(find.text("We've updated our Terms of Service"), findsOneWidget);
    expect(find.text('Read the Terms of Service'), findsOneWidget);
    expect(_acceptButton(tester).onPressed, isNull);

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();

    expect(_acceptButton(tester).onPressed, isNotNull);
  });

  testWidgets('accepting records exactly the version it was shown, then closes', (tester) async {
    final repository = MockProfileRepository();
    await _open(tester, repository);

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.tap(find.text('Accept and continue'));
    await tester.pumpAndSettle();

    expect(repository.acceptedTermsVersions, ['2099-01-01']);
    expect(find.byType(TermsUpdateDialog), findsNothing);
  });

  testWidgets('a failed save keeps the dialog open, says so, and lets them try again', (tester) async {
    final repository = _FlakyProfileRepository();
    await _open(tester, repository);
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();

    await tester.tap(find.text('Accept and continue'));
    await tester.pumpAndSettle();

    expect(find.byType(TermsUpdateDialog), findsOneWidget);
    expect(find.text("Couldn't save your choice. Check your connection and try again."), findsOneWidget);
    expect(repository.acceptedTermsVersions, isEmpty);

    await tester.tap(find.text('Accept and continue'));
    await tester.pumpAndSettle();

    expect(repository.acceptedTermsVersions, ['2099-01-01']);
    expect(find.byType(TermsUpdateDialog), findsNothing);
  });

  testWidgets('the back gesture cannot dismiss it', (tester) async {
    await _open(tester, MockProfileRepository());

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(TermsUpdateDialog), findsOneWidget);
  });

  testWidgets('the Terms are one tap away before deciding', (tester) async {
    await _open(tester, MockProfileRepository());

    await tester.tap(find.text('Read the Terms of Service'));
    await tester.pumpAndSettle();

    expect(find.byType(TermsOfServiceScreen), findsOneWidget);
  });

  testWidgets('logging out instead records nothing', (tester) async {
    var loggedOut = false;
    final repository = MockProfileRepository();
    await _open(tester, repository, onLogout: () async => loggedOut = true);

    await tester.tap(find.text('Log out instead'));
    await tester.pumpAndSettle();

    expect(loggedOut, isTrue);
    expect(repository.acceptedTermsVersions, isEmpty);
    expect(find.byType(TermsUpdateDialog), findsNothing);
  });

  testWidgets('is translated', (tester) async {
    LocaleController.debugSetInstance(LocaleController(storage: InMemoryTokenStorage()));
    await LocaleController.instance.setLocale('fr');
    await _open(tester, MockProfileRepository());

    expect(find.text("Nous avons mis à jour nos conditions d'utilisation"), findsOneWidget);
    expect(find.text('Accepter et continuer'), findsOneWidget);
  });
}
