import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/data/offline_slots_policy.dart';
import 'package:spekooh/data/repositories/profile_repository.dart';
import 'package:spekooh/models/spekooh_user.dart';

import 'support/l10n_test_app.dart';

const _freeUser = SpekoohUser(
  name: 'Lucien',
  joinDate: 'Joined Aug 2026',
  submissionsCount: 0,
  quizzesCount: 0,
  creditBalance: 0,
  redeemCode: '',
  redeemCodeSubtitle: '',
);

const _plusUser = SpekoohUser(
  name: 'Lucien',
  joinDate: 'Joined Aug 2026',
  submissionsCount: 0,
  quizzesCount: 0,
  creditBalance: 0,
  redeemCode: '',
  redeemCodeSubtitle: '',
  isPlusSubscriber: true,
);

Future<bool?> _run(WidgetTester tester, {required int currentCount, required SpekoohUser user}) async {
  bool? result;
  await tester.pumpWidget(l10nTestApp(
    Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            result = await confirmOfflineSlotAvailable(
              context,
              currentCount: currentCount,
              profileRepository: MockProfileRepository(user: user),
              errorMessage: (l10n) => l10n.offlineSlotsFullPapersError(kMaxOfflineSlots),
            );
          },
          child: const Text('go'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('go'));
  await tester.pump();
  return result;
}

void main() {
  test('kMaxOfflineSlots is 3, matching the mockup', () {
    expect(kMaxOfflineSlots, 3);
  });

  testWidgets('a free account under the cap may save', (tester) async {
    final result = await _run(tester, currentCount: 2, user: _freeUser);

    expect(result, isTrue);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('a free account at the cap is refused, with a real explanation shown', (tester) async {
    final result = await _run(tester, currentCount: 3, user: _freeUser);

    expect(result, isFalse);
    expect(find.text('Keep 3 papers offline at a time. Remove one to save another.'), findsOneWidget);
  });

  testWidgets('a Kawlo Plus subscriber is never capped, even already at 3', (tester) async {
    final result = await _run(tester, currentCount: 10, user: _plusUser);

    expect(result, isTrue);
    expect(find.byType(SnackBar), findsNothing);
  });
}
