import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/data/repositories/papers_repository.dart';
import 'package:spekooh/widgets/paper_summary_card.dart';

import 'support/l10n_test_app.dart';

class _FakePapersRepository implements PapersRepository {
  _FakePapersRepository(this._result);
  final PaperSummaryResult? _result;
  int calls = 0;

  @override
  Future<PaperSummaryResult?> getPaperSummary(int paperId) async {
    calls++;
    return _result;
  }

  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName} not used by PaperSummaryCard tests');
}

/// A fake whose call never implements getPaperSummary at all — mirrors a
/// stale test double written before this feature existed, to prove the
/// widget's own catch-all keeps it from crashing the screen (see
/// PaperSummaryCard._load's doc comment).
class _NoSummaryMethodRepository implements PapersRepository {
  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  testWidgets('renders nothing while the first load is in flight, then nothing once it resolves to null', (tester) async {
    await tester.pumpWidget(l10nTestApp(PaperSummaryCard(paperId: 1, repository: _FakePapersRepository(null))));
    await tester.pump();

    expect(find.byType(PaperSummaryCard), findsOneWidget);
    expect(find.text('AI summary'), findsNothing);
  });

  testWidgets('a ready summary shows the real body and the AI disclaimer', (tester) async {
    const result = PaperSummaryResult(status: PaperSummaryStatus.ready, body: 'This paper covers photosynthesis.');
    await tester.pumpWidget(l10nTestApp(PaperSummaryCard(paperId: 1, repository: _FakePapersRepository(result))));
    await tester.pump();

    expect(find.text('AI summary'), findsOneWidget);
    expect(find.text('This paper covers photosynthesis.'), findsOneWidget);
    expect(find.textContaining('AI-generated'), findsOneWidget);
  });

  testWidgets('a pending summary shows a generating message and a Check again button', (tester) async {
    const result = PaperSummaryResult(status: PaperSummaryStatus.pending);
    final repo = _FakePapersRepository(result);
    await tester.pumpWidget(l10nTestApp(PaperSummaryCard(paperId: 1, repository: repo)));
    await tester.pump();

    expect(find.text('Generating a summary of this paper…'), findsOneWidget);
    expect(find.text('Check again'), findsOneWidget);

    await tester.tap(find.text('Check again'));
    await tester.pump();

    expect(repo.calls, 2); // the initial load, plus the manual retry
  });

  testWidgets('a failed summary shows a distinct message from "generating"', (tester) async {
    const result = PaperSummaryResult(status: PaperSummaryStatus.failed);
    await tester.pumpWidget(l10nTestApp(PaperSummaryCard(paperId: 1, repository: _FakePapersRepository(result))));
    await tester.pump();

    expect(find.text("A summary isn't available for this paper yet."), findsOneWidget);
    expect(find.text('Generating a summary of this paper…'), findsNothing);
  });

  testWidgets('a repository that throws (or has no real implementation at all) never crashes the screen', (tester) async {
    await tester.pumpWidget(l10nTestApp(PaperSummaryCard(paperId: 1, repository: _NoSummaryMethodRepository())));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('AI summary'), findsNothing);
  });
}
