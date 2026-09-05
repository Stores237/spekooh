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
import 'package:spekooh/data/repositories/papers_repository.dart';
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

  test('createSubject tolerates the blank tint the backend always returns for a new subject', () async {
    final mockClient = MockClient((request) async {
      return http.Response(
        jsonEncode({'id': 9, 'key': 'geology', 'title': 'Geology', 'code': '', 'icon_name': '', 'tint': '', 'language': 'en'}),
        201,
        headers: {'content-type': 'application/json'},
      );
    });
    final repo = HttpPapersRepository(ApiClient(authSession: AuthSession(storage: InMemoryTokenStorage()), httpClient: mockClient));

    final subject = await repo.createSubject(title: 'Geology', examTypeName: 'O Level');

    expect(subject.title, 'Geology');
    expect(subject.tint, IconChipTint.blue);
  });

  test('createSubject sends a guest bearer override instead of the (absent) session token', () async {
    String? authHeader;
    final mockClient = MockClient((request) async {
      authHeader = request.headers['Authorization'];
      return http.Response(
        jsonEncode({'id': 9, 'key': 'geology', 'title': 'Geology', 'code': '', 'icon_name': '', 'tint': '', 'language': 'en'}),
        201,
        headers: {'content-type': 'application/json'},
      );
    });
    // No accessToken set — a real guest (never logged in) has none.
    final repo = HttpPapersRepository(ApiClient(authSession: AuthSession(storage: InMemoryTokenStorage()), httpClient: mockClient));

    await repo.createSubject(title: 'Geology', examTypeName: 'O Level', guestAccessToken: 'guest-token-123');

    expect(authHeader, 'Bearer guest-token-123');
  });

  // Direct-to-storage upload (2026-08-30 latency fix): a live timed test
  // isolated the slow "submitted" message to Django's own synchronous
  // re-upload of the file to Supabase Storage. The client now PUTs the
  // bytes straight to storage first, then submits only a small metadata
  // request — see HttpPapersRepository.submitPaper.
  group('submitPaper', () {
    const file = SubmissionFile(bytes: [1, 2, 3, 4], fileName: 'gce-bio-2024.pdf', mimeType: 'application/pdf');

    test('uploads directly to storage when the server offers a presigned URL, skipping multipart', () async {
      final requests = <http.Request>[];
      final mockClient = MockClient((request) async {
        requests.add(request);
        if (request.url.path.endsWith('/upload_url/')) {
          return http.Response(
            jsonEncode({'upload_url': 'https://storage.example.com/put/some-key', 'storage_key': 'paper_submissions/2026/08/abc123.pdf'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.host == 'storage.example.com') {
          expect(request.method, 'PUT');
          expect(request.bodyBytes, file.bytes);
          return http.Response('', 200);
        }
        // The final metadata POST — a real submission-create response.
        expect(jsonDecode(request.body)['storage_key'], 'paper_submissions/2026/08/abc123.pdf');
        return http.Response(
          jsonEncode({'id': 42, 'year': 2024, 'status': 'PENDING_REVIEW'}),
          201,
          headers: {'content-type': 'application/json'},
        );
      });
      final repo = HttpPapersRepository(ApiClient(authSession: AuthSession(storage: InMemoryTokenStorage()), httpClient: mockClient));

      final entry = await repo.submitPaper(categoryId: 1, examTypeId: 2, year: 2024, file: file);

      expect(entry.id, 42);
      // Never a multipart request — the whole point of this path.
      expect(requests.any((r) => r.headers['content-type']?.contains('multipart') ?? false), isFalse);
    });

    test('falls back to multipart when the server has no presigning concept (local-disk dev)', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/upload_url/')) {
          return http.Response(jsonEncode({'detail': "Direct upload isn't available on this server."}), 503);
        }
        // Multipart POST reaching the real submission-create endpoint.
        return http.Response(
          jsonEncode({'id': 7, 'year': 2024, 'status': 'PENDING_REVIEW'}),
          201,
          headers: {'content-type': 'application/json'},
        );
      });
      final repo = HttpPapersRepository(ApiClient(authSession: AuthSession(storage: InMemoryTokenStorage()), httpClient: mockClient));

      final entry = await repo.submitPaper(categoryId: 1, examTypeId: 2, year: 2024, file: file);

      expect(entry.id, 7);
    });

    test('falls back to multipart when the direct PUT itself fails', () async {
      var putAttempted = false;
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/upload_url/')) {
          return http.Response(
            jsonEncode({'upload_url': 'https://storage.example.com/put/some-key', 'storage_key': 'paper_submissions/2026/08/abc123.pdf'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.host == 'storage.example.com') {
          putAttempted = true;
          return http.Response('server error', 500);
        }
        return http.Response(
          jsonEncode({'id': 9, 'year': 2024, 'status': 'PENDING_REVIEW'}),
          201,
          headers: {'content-type': 'application/json'},
        );
      });
      final repo = HttpPapersRepository(ApiClient(authSession: AuthSession(storage: InMemoryTokenStorage()), httpClient: mockClient));

      final entry = await repo.submitPaper(categoryId: 1, examTypeId: 2, year: 2024, file: file);

      expect(putAttempted, isTrue);
      expect(entry.id, 9); // the submission still succeeds, via multipart
    });
  });

  group('getPaperSummary', () {
    test('a ready summary returns its real body', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/ai/papers/42/summary/'));
        return http.Response(jsonEncode({'status': 'ready', 'body': 'A real summary.'}), 200, headers: {'content-type': 'application/json'});
      });
      final repo = HttpPapersRepository(ApiClient(authSession: AuthSession(storage: InMemoryTokenStorage()), httpClient: mockClient));

      final result = await repo.getPaperSummary(42);

      expect(result?.status, PaperSummaryStatus.ready);
      expect(result?.body, 'A real summary.');
    });

    test('a still-generating summary reports pending with no body', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'status': 'pending', 'retry_after': 15}), 202, headers: {'content-type': 'application/json'});
      });
      final repo = HttpPapersRepository(ApiClient(authSession: AuthSession(storage: InMemoryTokenStorage()), httpClient: mockClient));

      final result = await repo.getPaperSummary(42);

      expect(result?.status, PaperSummaryStatus.pending);
      expect(result?.body, isNull);
    });

    // 402/404/503 are all real, valid "nothing to show" states from
    // apps.ai.views.PaperSummaryView — never an error worth surfacing for a
    // feature this optional.
    for (final code in [402, 404, 503]) {
      test('a $code response is treated as "no summary", not an error', () async {
        final mockClient = MockClient((request) async => http.Response(jsonEncode({'detail': 'nope'}), code, headers: {'content-type': 'application/json'}));
        final repo = HttpPapersRepository(ApiClient(authSession: AuthSession(storage: InMemoryTokenStorage()), httpClient: mockClient));

        expect(await repo.getPaperSummary(42), isNull);
      });
    }

    test('a genuine server error is a real exception, not silently swallowed', () async {
      final mockClient = MockClient((request) async => http.Response('boom', 500));
      final repo = HttpPapersRepository(ApiClient(authSession: AuthSession(storage: InMemoryTokenStorage()), httpClient: mockClient));

      expect(() => repo.getPaperSummary(42), throwsA(isA<ApiException>()));
    });
  });
}
