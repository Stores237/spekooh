import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:spekooh/data/api_client.dart';
import 'package:spekooh/data/auth_session.dart';
import 'package:spekooh/data/token_storage.dart';

/// package:http's own MockClient (used by api_client_test.dart) only ever
/// returns one buffered http.Response — fine for every other ApiClient
/// method, but postStream's whole job is parsing SSE frames as raw bytes
/// arrive, potentially split across multiple network chunks. This fake
/// hands back exactly the byte chunks the test wants, in order, so that
/// splitting can be tested for real instead of assumed.
class _FakeStreamingClient extends http.BaseClient {
  _FakeStreamingClient(this.chunks, {this.statusCode = 200});
  final List<List<int>> chunks;
  final int statusCode;
  http.BaseRequest? lastRequest;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastRequest = request;
    return http.StreamedResponse(Stream.fromIterable(chunks), statusCode);
  }
}

ApiClient _clientFor(_FakeStreamingClient fake) =>
    ApiClient(authSession: AuthSession(storage: InMemoryTokenStorage(), httpClient: fake), httpClient: fake, baseUrl: 'http://test/api');

void main() {
  test('postStream parses each SSE data: frame as a decoded JSON map, in order', () async {
    const body = 'data: {"delta":"Hello"}\n\ndata: {"delta":" there."}\n\ndata: {"done":true,"quota_remaining":3}\n\n';
    final api = _clientFor(_FakeStreamingClient([utf8.encode(body)]));

    final events = await api.postStream('/ai/papers/1/chat/', body: {'messages': []}).toList();

    expect(events, [
      {'delta': 'Hello'},
      {'delta': ' there.'},
      {'done': true, 'quota_remaining': 3},
    ]);
  });

  test('a single SSE frame split across multiple network chunks still parses as one event', () async {
    // Real TCP/HTTP chunking has no idea where a logical SSE frame begins
    // or ends — this is exactly the case ApiClient.postStream's own buffer
    // exists for. Split deliberately mid-payload AND mid-delimiter.
    const full = 'data: {"delta":"Hello there."}\n\n';
    final bytes = utf8.encode(full);
    final fake = _FakeStreamingClient([bytes.sublist(0, 10), bytes.sublist(10, 20), bytes.sublist(20)]);
    final api = _clientFor(fake);

    final events = await api.postStream('/ai/papers/1/chat/', body: {'messages': []}).toList();

    expect(events, [
      {'delta': 'Hello there.'},
    ]);
  });

  test('a non-2xx status throws ApiException with the real body, before any frame is read', () async {
    final fake = _FakeStreamingClient([utf8.encode('{"detail":"AI chat is busy right now."}')], statusCode: 503);
    final api = _clientFor(fake);

    await expectLater(
      api.postStream('/ai/papers/1/chat/', body: {'messages': []}).toList(),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 503)),
    );
  });

  test('sends the Accept: text/event-stream header the backend uses for content negotiation', () async {
    const body = 'data: {"done":true,"quota_remaining":null}\n\n';
    final fake = _FakeStreamingClient([utf8.encode(body)]);
    final api = _clientFor(fake);

    await api.postStream('/ai/papers/1/chat/', body: {'messages': []}).toList();

    expect(fake.lastRequest?.headers['Accept'], 'text/event-stream');
  });
}
