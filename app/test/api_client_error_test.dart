import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/data/api_client.dart';

/// Owner-reported (2026-09-02, from a live screenshot): a raw exception's
/// own text — for a network failure, a SocketException/ClientException
/// whose message includes the backend's real hostname and port — was being
/// shown straight to the user. apiErrorDetail is the fix: only ever surface
/// the backend's own curated `detail` message (safe — every one of this
/// codebase's own domain exceptions carries a hardcoded, human-authored
/// string, verified against every "information exposure through an
/// exception" CodeQL finding at the time), never a raw exception's text.
void main() {
  test('extracts the safe detail message from a real backend error response', () {
    final error = ApiException(402, '{"detail": "Already unlocked."}');
    expect(apiErrorDetail(error), 'Already unlocked.');
  });

  test('returns null for a non-JSON body instead of leaking it', () {
    // e.g. an unhandled 500's plain-text/HTML Django error page.
    final error = ApiException(500, '<html><body>Internal Server Error</body></html>');
    expect(apiErrorDetail(error), isNull);
  });

  test('returns null when the JSON body has no detail field', () {
    final error = ApiException(400, '{"field": ["This field is required."]}');
    expect(apiErrorDetail(error), isNull);
  });

  test('returns null for a raw network exception, never its own text', () {
    // The real reported bug: a SocketException's toString() includes the
    // backend's hostname and port — must never reach a user-facing string.
    final error = Exception(
      'ClientException with SocketException: Connection reset by peer (OS Error: Connection reset by '
      'peer, errno = 104), address = spekooh-staging.onrender.com, port = 42216, '
      'uri=https://spekooh-staging.onrender.com/api/papers/categories/',
    );
    expect(apiErrorDetail(error), isNull);
  });
}
