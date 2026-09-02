import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'auth_session.dart';

/// Base URL for the Django backend. Override at build/run time with
/// `--dart-define=API_BASE_URL=http://<host>:8000/api`.
///
/// `10.0.2.2` is the Android emulator's alias for the host machine — it
/// resolves to nothing on web, so requests there just hang until timeout
/// instead of failing fast. Web needs the real host. For an iOS simulator
/// this also correctly resolves via `localhost`; for a physical device use
/// your machine's LAN IP via the dart-define above.
const String _defaultBaseUrl = kIsWeb ? 'http://localhost:8000/api' : 'http://10.0.2.2:8000/api';

/// Generous rather than snappy — a free-tier host (e.g. Render's staging
/// plan, see RENDER_STAGING.md) spins down after 15 minutes idle and takes
/// roughly a minute to wake on the next request. Every request path below
/// used to have no timeout at all — an unreachable host just hung forever
/// with no error and no way for the UI to ever recover — so this is a
/// strict improvement even against a normal always-on host.
const Duration _requestTimeout = Duration(seconds: 90);

class ApiException implements Exception {
  ApiException(this.statusCode, this.body);
  final int statusCode;
  final String body;

  @override
  String toString() => 'ApiException($statusCode): $body';
}

/// Owner-reported (2026-09-02, from a live screenshot): a raw caught
/// exception's own toString() was being shown straight to the user in
/// several screens' error SnackBars — for a network failure that's a
/// SocketException/ClientException whose text includes the backend's real
/// hostname and port ("...address = spekooh-staging.onrender.com, port =
/// 42216..."), and for an ApiException it's the class name plus the raw
/// JSON body. Neither belongs in front of a user.
///
/// The backend's own error responses are already safe to show as-is — every
/// `{"detail": str(exc)}` in this codebase's views wraps one of its own
/// curated domain exceptions (PaperUnlockError("Already unlocked."),
/// RedeemCodeError("Redeem code has expired."), etc. — verified 2026-09-02
/// against every "information exposure through an exception" CodeQL finding
/// at the time, none of which wrap a real system exception). So an
/// ApiException's `detail` is worth surfacing; anything else (a network
/// failure before any response ever came back, a malformed/non-JSON body,
/// or an unexpected exception type) is not — callers should fall back to a
/// generic, translated message (AppLocalizations.authErrorUnknown reads
/// naturally for this) instead.
String? apiErrorDetail(Object error) {
  if (error is! ApiException) return null;
  try {
    final body = jsonDecode(error.body);
    if (body is Map && body['detail'] is String) return body['detail'] as String;
  } catch (_) {
    // Not JSON (e.g. an HTML error page from an unhandled 500) — no safe
    // detail to extract, fall through to the generic fallback.
  }
  return null;
}

/// Thin JSON HTTP client: attaches the bearer access token to every request,
/// and on a 401 attempts exactly one silent refresh-and-retry via
/// [AuthSession] before surfacing the error.
class ApiClient {
  ApiClient({required this.authSession, http.Client? httpClient, String? baseUrl})
      : _client = httpClient ?? http.Client(),
        baseUrl = baseUrl ?? const String.fromEnvironment('API_BASE_URL', defaultValue: _defaultBaseUrl);

  final AuthSession authSession;
  final http.Client _client;
  final String baseUrl;

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query?.isEmpty ?? true ? null : query);

  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _send('GET', _uri(path, query));

  /// [bearerTokenOverride]: same idea as [postMultipart]'s param of the same
  /// name — authorizes just this call with a token that isn't this
  /// session's own (e.g. a guest contributor's, for creating a subject
  /// before/without ever submitting a paper).
  Future<dynamic> post(String path, {Object? body, String? bearerTokenOverride}) =>
      _send('POST', _uri(path), body: body, bearerTokenOverride: bearerTokenOverride);

  Future<dynamic> patch(String path, {Object? body}) => _send('PATCH', _uri(path), body: body);

  Future<dynamic> delete(String path) => _send('DELETE', _uri(path));

  /// Multipart POST for real file uploads (e.g. paper submission scans).
  /// [fields] are form fields sent alongside the file as plain strings.
  /// [method] is POST by default; pass 'PATCH' for an update-in-place
  /// upload (e.g. ProfileRepository.updateAvatar against /auth/me/, which
  /// DRF's RetrieveUpdateAPIView only accepts PATCH/PUT for).
  /// [bearerTokenOverride] authorizes just this call with a token that
  /// isn't this session's own (e.g. a guest contributor's — see
  /// AuthSession.mintGuestAccessToken) instead of [authSession]'s; a guest
  /// token has no refresh token behind it, so the 401-refresh-retry below
  /// is skipped whenever an override is given.
  Future<dynamic> postMultipart(
    String path, {
    required String fileFieldName,
    required List<int> fileBytes,
    required String fileName,
    String? mimeType,
    Map<String, String> fields = const {},
    String? bearerTokenOverride,
    String method = 'POST',
    bool isRetry = false,
  }) async {
    final uri = _uri(path);
    final request = http.MultipartRequest(method, uri)
      ..fields.addAll(fields)
      ..files.add(http.MultipartFile.fromBytes(
        fileFieldName,
        fileBytes,
        filename: fileName,
        contentType: mimeType != null ? MediaType.parse(mimeType) : null,
      ));
    final access = bearerTokenOverride ?? authSession.accessToken;
    if (access != null) request.headers['Authorization'] = 'Bearer $access';

    final streamed = await _client.send(request).timeout(_requestTimeout);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 401 && !isRetry && bearerTokenOverride == null && authSession.refreshToken != null) {
      final refreshed = await authSession.refreshAccessToken();
      if (refreshed) {
        return postMultipart(
          path,
          fileFieldName: fileFieldName,
          fileBytes: fileBytes,
          fileName: fileName,
          mimeType: mimeType,
          fields: fields,
          method: method,
          isRetry: true,
        );
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }

  /// Raw PUT of file bytes to an absolute URL that is NOT this API's own
  /// baseUrl — used only for direct-to-storage uploads (see
  /// PapersRepository.submitPaper): the URL is a presigned Supabase Storage
  /// link handed back by /papers/submissions/upload_url/, so no bearer
  /// token or JSON content-type belongs on this request at all, and the
  /// usual 401-refresh-retry doesn't apply (a presigned URL doesn't 401).
  Future<void> putBytes(String absoluteUrl, {required List<int> bytes, String? contentType}) async {
    final response = await _client
        .put(
          Uri.parse(absoluteUrl),
          headers: contentType != null ? {'Content-Type': contentType} : null,
          body: bytes,
        )
        .timeout(_requestTimeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  Future<dynamic> _send(String method, Uri uri, {Object? body, String? bearerTokenOverride, bool isRetry = false}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final access = bearerTokenOverride ?? authSession.accessToken;
    if (access != null) headers['Authorization'] = 'Bearer $access';

    final response = await _request(method, uri, headers, body);

    if (response.statusCode == 401 && !isRetry && bearerTokenOverride == null && authSession.refreshToken != null) {
      final refreshed = await authSession.refreshAccessToken();
      if (refreshed) return _send(method, uri, body: body, isRetry: true);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }
    throw ApiException(response.statusCode, response.body);
  }

  Future<http.Response> _request(String method, Uri uri, Map<String, String> headers, Object? body) {
    final encoded = body == null ? null : jsonEncode(body);
    switch (method) {
      case 'GET':
        return _client.get(uri, headers: headers).timeout(_requestTimeout);
      case 'POST':
        return _client.post(uri, headers: headers, body: encoded).timeout(_requestTimeout);
      case 'PATCH':
        return _client.patch(uri, headers: headers, body: encoded).timeout(_requestTimeout);
      case 'DELETE':
        return _client.delete(uri, headers: headers).timeout(_requestTimeout);
      default:
        throw ArgumentError('Unsupported method: $method');
    }
  }
}
