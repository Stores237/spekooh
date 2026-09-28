// Reading a summary note: opened from a row on the Notes list.
import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/data/locale_controller.dart';
import 'package:spekooh/data/repositories/notes_repository.dart';
import 'package:spekooh/data/token_storage.dart';
import 'package:spekooh/models/note.dart';
import 'package:spekooh/screens/notes/note_detail_screen.dart';
import 'package:spekooh/screens/notes/notes_screen.dart';
import 'package:spekooh/widgets/icon_chip.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'support/l10n_test_app.dart';

const _listRow = Note(
  id: 7,
  title: 'Acids, Bases & Salts',
  subtitle: 'Chemistry · O Level',
  tint: IconChipTint.purple,
  icon: LucideIcons.flaskConical,
);

Note _withBody(String body) => Note(
      id: 7,
      title: _listRow.title,
      subtitle: _listRow.subtitle,
      tint: IconChipTint.purple,
      icon: LucideIcons.flaskConical,
      body: body,
    );

class _StubNotes implements NotesRepository {
  _StubNotes(this._results);
  final List<Object> _results; // a Note to return, or anything else to throw
  int getNoteCalls = 0;

  @override
  Future<List<Note>> getNotes() async => const [_listRow];

  @override
  Future<Note> getNote(int id) async {
    final result = _results[getNoteCalls < _results.length ? getNoteCalls : _results.length - 1];
    getNoteCalls++;
    if (result is Note) return result;
    throw Exception('offline');
  }
}

Future<void> _open(WidgetTester tester, NotesRepository repository) async {
  await tester.pumpWidget(l10nTestApp(NoteDetailScreen(note: _listRow, repository: repository)));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  tearDown(() {
    LocaleController.debugSetInstance(LocaleController(storage: InMemoryTokenStorage()));
  });

  testWidgets('shows the title and level at once, then the note as paragraphs, a heading and bullets', (tester) async {
    await _open(tester, _StubNotes([_withBody('Acids and bases make a salt.\n\n## Neutralisation\n- acid + base → salt + water')]));

    expect(find.text('Acids, Bases & Salts'), findsOneWidget);
    expect(find.text('Chemistry · O Level'), findsOneWidget);
    expect(find.text('Acids and bases make a salt.'), findsOneWidget);
    expect(find.text('Neutralisation'), findsOneWidget);
    expect(find.text('acid + base → salt + water'), findsOneWidget);
  });

  testWidgets('a note with no text yet says so instead of showing an empty page', (tester) async {
    await _open(tester, _StubNotes([_withBody('')]));

    expect(find.text("The text for this note isn't available yet."), findsOneWidget);
  });

  testWidgets('a failed load explains and offers to try again, and trying again works', (tester) async {
    final repository = _StubNotes(['fail', _withBody('Now it loads.')]);
    await _open(tester, repository);

    expect(find.text("Couldn't open this note. Check your connection and try again."), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Now it loads.'), findsOneWidget);
    expect(repository.getNoteCalls, 2);
  });

  testWidgets('is translated', (tester) async {
    LocaleController.debugSetInstance(LocaleController(storage: InMemoryTokenStorage()));
    await LocaleController.instance.setLocale('fr');
    await _open(tester, _StubNotes([_withBody('')]));

    expect(find.text("Le texte de cette note n'est pas encore disponible."), findsOneWidget);
  });

  testWidgets('tapping a note on the list opens it, and back returns to the list', (tester) async {
    await tester.pumpWidget(l10nTestApp(NotesScreen(repository: MockNotesRepository())));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('Mechanics: Newton’s Laws'));
    await tester.pumpAndSettle();

    expect(find.byType(NoteDetailScreen), findsOneWidget);
    expect(find.textContaining('Newton\'s three laws'), findsOneWidget); // the real text from the mock note

    await tester.tap(find.byIcon(LucideIcons.chevronLeft));
    await tester.pumpAndSettle();

    expect(find.byType(NoteDetailScreen), findsNothing);
    expect(find.byType(NotesScreen), findsOneWidget);
  });
}
