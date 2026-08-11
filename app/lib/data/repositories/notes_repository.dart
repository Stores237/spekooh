import '../../models/note.dart';
import '../mock/mock_notes.dart';

abstract class NotesRepository {
  Future<List<Note>> getNotes();
}

class MockNotesRepository implements NotesRepository {
  @override
  Future<List<Note>> getNotes() => Future.value(mockNotes);
}
