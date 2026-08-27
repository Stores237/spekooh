// Regression test for the "Matière/Subject picker went permanently
// unresponsive" bug: a contributor-added subject (SubjectSerializer.create
// on the backend) deliberately leaves tint/icon_name/code blank for later
// curation, and getSubjects used to parse tint via `.byName(...)`, which
// throws on a blank/unrecognized string — breaking the *entire* subject
// list, not just that one row, for every contributor from then on.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:spekooh/data/api_client.dart';
import 'package:spekooh/data/auth_session.dart';
import 'package:spekooh/data/repositories/http/http_papers_repository.dart';
import 'package:spekooh/data/token_storage.dart';
import 'package:spekooh/widgets/icon_chip.dart';

void main() {
  test('getSubjects tolerates a blank tint (contributor-added subject) instead of throwing', () async {
    final mockClient = MockClient((request) async {
      return http.Response(
        jsonEncode([
          {'id': 1, 'key': 'physics', 'title': 'Physics', 'code': '0580', 'icon_name': 'bolt_outlined', 'tint': 'blue', 'language': 'en'},
          // Contributor-added: tint/icon_name/code genuinely blank, not null.
          {'id': 2, 'key': 'geology', 'title': 'Geology', 'code': '', 'icon_name': '', 'tint': '', 'language': 'en'},
        ]),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final repo = HttpPapersRepository(ApiClient(authSession: AuthSession(storage: InMemoryTokenStorage()), httpClient: mockClient));

    final subjects = await repo.getSubjects('O Level');

    expect(subjects, hasLength(2));
    expect(subjects[0].tint, IconChipTint.blue);
    // The blank-tint row must fall back to a default, not throw.
    expect(subjects[1].title, 'Geology');
    expect(subjects[1].tint, IconChipTint.blue);
  });
}
