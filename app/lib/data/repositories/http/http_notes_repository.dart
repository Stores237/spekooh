import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../models/note.dart';
import '../../../widgets/icon_chip.dart';
import '../../api_client.dart';
import '../notes_repository.dart';

class HttpNotesRepository implements NotesRepository {
  HttpNotesRepository(this._client);
  final ApiClient _client;

  // The backend note has no icon or tint (cosmetic-only), so every note gets
  // the same placeholder.
  Note _fromRow(Map<String, dynamic> row) => Note(
        id: row['id'] as int,
        title: row['title'] as String,
        subtitle: row['subtitle'] as String? ?? '',
        tint: IconChipTint.blue,
        icon: LucideIcons.fileText,
        subjectTitle: row['subject_title'] as String? ?? '',
        academicLevel: row['academic_level'] as String? ?? '',
        body: row['body'] as String? ?? '',
      );

  @override
  Future<List<Note>> getNotes() async {
    final rows = await _client.get('/notes/') as List;
    return rows.map((row) => _fromRow(row as Map<String, dynamic>)).toList();
  }

  @override
  Future<Note> getNote(int id) async {
    return _fromRow(await _client.get('/notes/$id/') as Map<String, dynamic>);
  }
}
