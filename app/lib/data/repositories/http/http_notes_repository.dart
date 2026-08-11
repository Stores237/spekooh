import 'package:flutter/material.dart';

import '../../../models/note.dart';
import '../../../widgets/icon_chip.dart';
import '../../api_client.dart';
import '../notes_repository.dart';

class HttpNotesRepository implements NotesRepository {
  HttpNotesRepository(this._client);
  final ApiClient _client;

  @override
  Future<List<Note>> getNotes() async {
    final rows = await _client.get('/notes/') as List;
    return rows.map((row) {
      return Note(
        id: row['id'] as int,
        title: row['title'] as String,
        subtitle: row['subtitle'] as String? ?? '',
        // The backend note model carries no icon/tint (cosmetic-only, spec §-unconfirmed feature) — fixed placeholder.
        tint: IconChipTint.blue,
        icon: Icons.description_outlined,
      );
    }).toList();
  }
}
