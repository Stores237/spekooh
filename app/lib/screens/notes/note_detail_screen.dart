import 'package:flutter/material.dart';
import '../../data/repositories/notes_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../models/note.dart';
import '../../models/note_body.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../../widgets/spekooh_button.dart';
import '../common/circular_back_button.dart';

/// Reads one summary note. Opened from a row on [NotesScreen]. The list row
/// already knows the title and the "Subject · Level" line, so those show at
/// once and only the text is fetched (GET /notes/{id}/).
///
/// A note with no text yet says so plainly rather than showing an empty page:
/// staff can create a note before it is written (the admin's "still to write"
/// count), and testers should be told, not left wondering.
class NoteDetailScreen extends StatefulWidget {
  const NoteDetailScreen({super.key, required this.note, required this.repository});

  final Note note;
  final NotesRepository repository;

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late Future<Note> _future = widget.repository.getNote(widget.note.id);

  void _retry() {
    setState(() {
      _future = widget.repository.getNote(widget.note.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.surfaceBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.space2),
              CircularBackButton(onTap: () => Navigator.of(context).pop()),
              const SizedBox(height: AppSpacing.space4),
              Text(
                widget.note.title,
                style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 22, color: AppColors.textPrimary),
              ),
              if (widget.note.subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  widget.note.subtitle,
                  style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
              const SizedBox(height: AppSpacing.space4),
              Expanded(
                child: FutureBuilder<Note>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                    }
                    if (snapshot.hasError) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.noteLoadError,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 14, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: AppSpacing.space4),
                          SpekoohButton(onPressed: _retry, child: Text(l10n.noteTryAgain)),
                        ],
                      );
                    }
                    final blocks = parseNoteBody(snapshot.data!.body);
                    if (blocks.isEmpty) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          l10n.noteNoTextYet,
                          style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 14, color: AppColors.textSecondary),
                        ),
                      );
                    }
                    return Container(
                      width: double.infinity,
                      decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(18)),
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [for (final block in blocks) _block(block)],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _block(NoteBlock block) {
    switch (block.kind) {
      case NoteBlockKind.heading:
        return Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6),
          child: Text(
            block.text,
            style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary),
          ),
        );
      case NoteBlockKind.bullet:
        return Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('•  ', style: TextStyle(fontSize: 15, color: AppColors.gold600, height: 1.5)),
              Expanded(
                child: Text(block.text, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 15, color: AppColors.textPrimary, height: 1.5)),
              ),
            ],
          ),
        );
      case NoteBlockKind.paragraph:
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(block.text, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 15, color: AppColors.textPrimary, height: 1.55)),
        );
    }
  }
}
