import '../../models/note.dart';
import '../mock/mock_notes.dart';

abstract class NotesRepository {
  Future<List<Note>> getNotes();

  /// One note with its text (`GET /notes/{id}/`).
  Future<Note> getNote(int id);
}

class MockNotesRepository implements NotesRepository {
  @override
  Future<List<Note>> getNotes() => Future.value(mockNotes);

  @override
  Future<Note> getNote(int id) {
    final matches = mockNotes.where((note) => note.id == id);
    return matches.isEmpty ? Future.error(StateError('No mock note $id')) : Future.value(matches.first);
  }
}
