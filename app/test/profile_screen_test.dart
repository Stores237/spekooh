import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:spekooh/data/achievement_definitions.dart';
import 'package:spekooh/data/auth_session.dart';
import 'package:spekooh/data/repositories/profile_repository.dart';
import 'package:spekooh/data/token_storage.dart';
import 'package:spekooh/models/achievement.dart';
import 'package:spekooh/models/spekooh_user.dart';
import 'package:spekooh/models/submission.dart';
import 'package:spekooh/screens/profile/profile_screen.dart';
import 'package:spekooh/sheets/achievements_sheet.dart';

import 'support/l10n_test_app.dart';

/// Real "Edit profile" (owner decision, 2026-08-28, adapting a reference
/// username/email/phone edit sheet) + real, honest badges computed from
/// counts already in [SpekoohUser] — replacing what was previously an
/// always-empty grid. See data/achievement_definitions.dart.
class _EditableProfileRepository implements ProfileRepository {
  _EditableProfileRepository(this._user);
  SpekoohUser _user;
  int updateCalls = 0;

  @override
  Future<SpekoohUser> getUser() async => _user;

  @override
  Future<List<Achievement>> getAchievements(SpekoohUser user) async => computeAchievements(user);

  @override
  Future<List<Submission>> getSubmissions() async => const [];

  @override
  Future<void> updateProfile({required String name, required String email, required String phoneNumber}) async {
    updateCalls++;
    _user = SpekoohUser(
      name: name,
      joinDate: _user.joinDate,
      submissionsCount: _user.submissionsCount,
      quizzesCount: _user.quizzesCount,
      creditBalance: _user.creditBalance,
      redeemCode: _user.redeemCode,
      redeemCodeSubtitle: _user.redeemCodeSubtitle,
      referralCode: _user.referralCode,
      email: email,
      phoneNumber: phoneNumber,
    );
  }

  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName} not used by profile-edit tests');
}

void _fakeLoggedIn() {
  final session = AuthSession(storage: InMemoryTokenStorage());
  session.accessToken = 'fake-access-token';
  AuthSession.debugSetInstance(session);
}

const _user = SpekoohUser(
  name: 'Original Name',
  joinDate: 'Joined Jul 2026',
  submissionsCount: 24,
  quizzesCount: 4,
  creditBalance: 2150,
  redeemCode: '',
  redeemCodeSubtitle: '',
  email: 'original@example.com',
  phoneNumber: '670000001',
);

void main() {
  tearDown(() {
    AuthSession.debugSetInstance(AuthSession(storage: InMemoryTokenStorage()));
  });

  group('Badges — real, honest state (owner decision, 2026-08-28)', () {
    testWidgets('earned/locked reflects real submission and quiz counts, not fabricated data', (tester) async {
      _fakeLoggedIn();
      // 24 submissions clears Spark/Ember/Inferno (>=1/5/15); 4 quizzes
      // does not clear Scholar I (>=10).
      await tester.pumpWidget(l10nTestApp(ProfileScreen(repository: _EditableProfileRepository(_user))));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.text('All 4'));
      await tester.pumpAndSettle();

      // ProfileScreen (and its own small badges grid) stays in the tree
      // behind the modal sheet — scope every lookup to the sheet itself so
      // duplicate "Spark" etc. text underneath doesn't ambiguate finders.
      final sheet = find.byType(AchievementsSheet);
      expect(find.descendant(of: sheet, matching: find.text('Spark')), findsOneWidget);
      expect(find.descendant(of: sheet, matching: find.text('Ember')), findsOneWidget);
      expect(find.descendant(of: sheet, matching: find.text('Inferno')), findsOneWidget);
      expect(find.descendant(of: sheet, matching: find.text('Scholar I')), findsOneWidget);
      // SpekoohBadge uppercases its label — assert the real rendered text.
      expect(find.descendant(of: sheet, matching: find.text('EARNED')), findsNWidgets(3)); // Spark, Ember, Inferno
      expect(find.descendant(of: sheet, matching: find.text('LOCKED')), findsNWidgets(1)); // Scholar I
    });
  });

  group('Edit profile (owner decision, 2026-08-28) — adapting a reference username/email/phone sheet', () {
    testWidgets('pencil icon opens a real sheet pre-filled with the current name/email/phone', (tester) async {
      _fakeLoggedIn();
      await tester.pumpWidget(l10nTestApp(ProfileScreen(repository: _EditableProfileRepository(_user))));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byIcon(LucideIcons.pencil));
      await tester.pumpAndSettle();

      expect(find.text('Edit profile'), findsOneWidget);
      // The profile card behind the sheet already shows "Original Name" —
      // 2 matches (card + pre-filled field) is the real, correct state.
      expect(find.text('Original Name'), findsNWidgets(2));
      expect(find.text('original@example.com'), findsOneWidget);
      expect(find.text('670000001'), findsOneWidget);
    });

    testWidgets('saving real changes updates the profile card immediately, without reopening the screen', (tester) async {
      _fakeLoggedIn();
      final repository = _EditableProfileRepository(_user);
      await tester.pumpWidget(l10nTestApp(ProfileScreen(repository: repository)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byIcon(LucideIcons.pencil));
      await tester.pumpAndSettle();

      final nameField = find.byType(TextField).at(0);
      await tester.enterText(nameField, 'New Name');
      await tester.tap(find.text('Save changes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300)); // let the sheet's closing transition finish

      expect(repository.updateCalls, 1);
      expect(find.text('New Name'), findsOneWidget); // the card itself, refreshed
      expect(find.text('Original Name'), findsNothing);
    });

    testWidgets('changing the email shows a real re-verification notice, since it resets on the backend', (tester) async {
      _fakeLoggedIn();
      final repository = _EditableProfileRepository(_user);
      await tester.pumpWidget(l10nTestApp(ProfileScreen(repository: repository)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byIcon(LucideIcons.pencil));
      await tester.pumpAndSettle();

      final emailField = find.byType(TextField).at(1);
      await tester.enterText(emailField, 'brandnew@example.com');
      await tester.tap(find.text('Save changes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300)); // let the sheet's closing transition finish

      expect(find.text('We sent a new verification code to your updated email.'), findsOneWidget);
    });

    testWidgets('saving without changing the email shows no re-verification notice', (tester) async {
      _fakeLoggedIn();
      final repository = _EditableProfileRepository(_user);
      await tester.pumpWidget(l10nTestApp(ProfileScreen(repository: repository)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byIcon(LucideIcons.pencil));
      await tester.pumpAndSettle();

      final phoneField = find.byType(TextField).at(2);
      await tester.enterText(phoneField, '670000009');
      await tester.tap(find.text('Save changes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300)); // let the sheet's closing transition finish

      expect(repository.updateCalls, 1);
      expect(find.text('We sent a new verification code to your updated email.'), findsNothing);
    });

    testWidgets('cancel discards changes without saving', (tester) async {
      _fakeLoggedIn();
      final repository = _EditableProfileRepository(_user);
      await tester.pumpWidget(l10nTestApp(ProfileScreen(repository: repository)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byIcon(LucideIcons.pencil));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Should Not Save');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(repository.updateCalls, 0);
      expect(find.text('Original Name'), findsOneWidget);
    });
  });

  group('Spekooh Pro promo (owner decision, 2026-08-28) — adapting a reference promo card', () {
    testWidgets('is a real, tappable entry to the paywall, not decorative', (tester) async {
      _fakeLoggedIn();
      var opened = false;
      await tester.pumpWidget(l10nTestApp(ProfileScreen(
        repository: _EditableProfileRepository(_user),
        onOpenPaywall: () => opened = true,
      )));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // The promo card sits below the fold on the test viewport — scroll it
      // into view first, same as a real device would let a user do.
      await tester.ensureVisible(find.text('Spekooh Pro'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Spekooh Pro'));
      expect(opened, isTrue);
    });
  });
}
