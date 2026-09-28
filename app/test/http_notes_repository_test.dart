// The list endpoint carries no text (it stays light); the detail endpoint does.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:spekooh/data/api_client.dart';
import 'package:spekooh/data/auth_session.dart';
import 'package:spekooh/data/repositories/http/http_notes_repository.dart';
import 'package:spekooh/data/token_storage.dart';

HttpNotesRepository _repo(http.Client client) =>
    HttpNotesRepository(ApiClient(authSession: AuthSession(storage: InMemoryTokenStorage()), httpClient: client));

http.Response _json(Object body) => http.Response(jsonEncode(body), 200, headers: {'content-type': 'application/json'});

void main() {
  test('the list maps each row without any text', () async {
    final repo = _repo(MockClient((request) async => _json([
          {'id': 1, 'title': 'A', 'subtitle': 'Physics · A Level', 'subject_title': 'Physics', 'academic_level': 'A Level'},
        ])));

    final notes = await repo.getNotes();

    expect(notes.single.id, 1);
    expect(notes.single.academicLevel, 'A Level');
    expect(notes.single.body, isEmpty);
  });

  test('one note is fetched from /notes/{id}/ and carries its text', () async {
    String? path;
    final repo = _repo(MockClient((request) async {
      path = request.url.path;
      return _json({'id': 5, 'title': 'A', 'subtitle': 'S', 'subject_title': 'X', 'academic_level': 'Y', 'body': 'Read me.'});
    }));

    final note = await repo.getNote(5);

    expect(path, endsWith('/notes/5/'));
    expect(note.body, 'Read me.');
  });

  test('a note the server sends without text is treated as empty, not as an error', () async {
    final repo = _repo(MockClient((request) async => _json({'id': 5, 'title': 'A'})));

    expect((await repo.getNote(5)).body, isEmpty);
  });

  test('a missing note surfaces as an error', () async {
    final repo = _repo(MockClient((request) async => http.Response('{"detail":"Not found."}', 404, headers: {'content-type': 'application/json'})));

    expect(() => repo.getNote(999), throwsA(anything));
  });
}
