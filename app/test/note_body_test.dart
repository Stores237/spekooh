// The note text format staff type in the admin: blank line = new paragraph,
// "## " = heading, "- " = bullet.
import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/models/note_body.dart';

void main() {
  test('paragraphs, headings and bullets come out in order', () {
    final blocks = parseNoteBody('Intro line.\n\n## Key ideas\n- one\n- two\n\nClosing words.');

    expect(blocks.map((b) => b.kind).toList(), [
      NoteBlockKind.paragraph,
      NoteBlockKind.heading,
      NoteBlockKind.bullet,
      NoteBlockKind.bullet,
      NoteBlockKind.paragraph,
    ]);
    expect(blocks.map((b) => b.text).toList(), ['Intro line.', 'Key ideas', 'one', 'two', 'Closing words.']);
  });

  test('lines with no blank line between them are one paragraph', () {
    final blocks = parseNoteBody('First line\nsecond line');

    expect(blocks, hasLength(1));
    expect(blocks.single.text, 'First line second line');
  });

  test('a paragraph that leads straight into bullets ends where the bullets start', () {
    final blocks = parseNoteBody('Work out b² − 4ac first:\n- positive: two solutions\n- zero: one solution');

    expect(blocks.map((b) => b.kind).toList(), [NoteBlockKind.paragraph, NoteBlockKind.bullet, NoteBlockKind.bullet]);
    expect(blocks.first.text, 'Work out b² − 4ac first:');
  });

  test('Windows line endings and stray spaces are handled', () {
    final blocks = parseNoteBody('  ## Title  \r\n\r\n  - item  \r\n');

    expect(blocks.map((b) => b.text).toList(), ['Title', 'item']);
  });

  test('empty or blank text has no blocks at all', () {
    expect(parseNoteBody(''), isEmpty);
    expect(parseNoteBody('  \n\n \n'), isEmpty);
  });
}
