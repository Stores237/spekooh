import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'auth_session.dart';

/// Base URL for the Django backend. Override at build/run time with
/// `--dart-define=API_BASE_URL=http://<host>:8000/api`.
///
/// Defaults to the standard Android-emulator-to-host address. For an iOS
/// simulator use `http://localhost:8000/api`; for a physical device use
/// your machine's LAN IP.
const String _defaultBaseUrl = 'http://10.0.2.2:8000/api';

class ApiException implements Exception {
  ApiException(this.statusCode, this.body);
  final int statusCode;
  final String body;

  @override
  String toString() => 'ApiException($statusCode): $body';
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

  Future<dynamic> post(String path, {Object? body}) => _send('POST', _uri(path), body: body);

  Future<dynamic> patch(String path, {Object? body}) => _send('PATCH', _uri(path), body: body);

  Future<dynamic> delete(String path) => _send('DELETE', _uri(path));

  /// Multipart POST for real file uploads (e.g. paper submission scans).
  /// [fields] are form fields sent alongside the file as plain strings.
  Future<dynamic> postMultipart(
    String path, {
    required String fileFieldName,
    required List<int> fileBytes,
    required String fileName,
    String? mimeType,
    Map<String, String> fields = const {},
    bool isRetry = false,
  }) async {
    final uri = _uri(path);
    final request = http.MultipartRequest('POST', uri)
      ..fields.addAll(fields)
      ..files.add(http.MultipartFile.fromBytes(
        fileFieldName,
        fileBytes,
        filename: fileName,
        contentType: mimeType != null ? MediaType.parse(mimeType) : null,
      ));
    final access = authSession.accessToken;
    if (access != null) request.headers['Authorization'] = 'Bearer $access';

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 401 && !isRetry && authSession.refreshToken != null) {
      final refreshed = await authSession.refreshAccessToken();
      if (refreshed) {
        return postMultipart(
          path,
          fileFieldName: fileFieldName,
          fileBytes: fileBytes,
          fileName: fileName,
          mimeType: mimeType,
          fields: fields,
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

  Future<dynamic> _send(String method, Uri uri, {Object? body, bool isRetry = false}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final access = authSession.accessToken;
    if (access != null) headers['Authorization'] = 'Bearer $access';

    final response = await _request(method, uri, headers, body);

    if (response.statusCode == 401 && !isRetry && authSession.refreshToken != null) {
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
        return _client.get(uri, headers: headers);
      case 'POST':
        return _client.post(uri, headers: headers, body: encoded);
      case 'PATCH':
        return _client.patch(uri, headers: headers, body: encoded);
      case 'DELETE':
        return _client.delete(uri, headers: headers);
      default:
        throw ArgumentError('Unsupported method: $method');
    }
  }
}
