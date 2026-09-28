/// A note's text is plain: a blank line starts a new paragraph, a line that
/// starts "## " is a heading and a line that starts "- " is a bullet. This is
/// the same format staff type in the admin (backend Note.body), so a note
/// never needs anything more than a text box to write.
enum NoteBlockKind { paragraph, heading, bullet }

class NoteBlock {
  const NoteBlock(this.kind, this.text);

  final NoteBlockKind kind;
  final String text;
}

List<NoteBlock> parseNoteBody(String body) {
  final blocks = <NoteBlock>[];
  final paragraph = <String>[];

  void flushParagraph() {
    if (paragraph.isEmpty) return;
    blocks.add(NoteBlock(NoteBlockKind.paragraph, paragraph.join(' ')));
    paragraph.clear();
  }

  for (final raw in body.replaceAll('\r\n', '\n').split('\n')) {
    final line = raw.trim();
    if (line.isEmpty) {
      flushParagraph();
    } else if (line.startsWith('## ')) {
      flushParagraph();
      blocks.add(NoteBlock(NoteBlockKind.heading, line.substring(3).trim()));
    } else if (line.startsWith('- ')) {
      flushParagraph();
      blocks.add(NoteBlock(NoteBlockKind.bullet, line.substring(2).trim()));
    } else {
      paragraph.add(line);
    }
  }
  flushParagraph();
  return blocks;
}
