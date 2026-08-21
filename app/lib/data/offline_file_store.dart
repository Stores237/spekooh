import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Byte-level storage for offline-saved paper files plus their index —
/// kept as its own seam (distinct from any specific plugin) so
/// [OfflinePapersStore] never touches `path_provider`/`dart:io` directly
/// and widget/unit tests can run against [InMemoryOfflineFileStore]
/// instead of real device storage.
abstract class OfflineFileStore {
  Future<void> writeBytes(String relativePath, List<int> bytes);
  Future<List<int>?> readBytes(String relativePath);
  Future<void> delete(String relativePath);

  /// A real, openable filesystem path for [relativePath] — only meaningful
  /// against [LocalOfflineFileStore]; callers only need this to hand off
  /// to a "open with the OS default app" plugin.
  Future<String> absolutePathFor(String relativePath);
}

/// Real, on-device storage under the app's own documents directory
/// (mobile-only — `path_provider` has no meaningful web implementation,
/// see spec §6 "no web app in v1").
class LocalOfflineFileStore implements OfflineFileStore {
  const LocalOfflineFileStore();

  Future<Directory> _dir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/offline_papers');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  @override
  Future<void> writeBytes(String relativePath, List<int> bytes) async {
    final dir = await _dir();
    await File('${dir.path}/$relativePath').writeAsBytes(bytes, flush: true);
  }

  @override
  Future<List<int>?> readBytes(String relativePath) async {
    final dir = await _dir();
    final file = File('${dir.path}/$relativePath');
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  @override
  Future<void> delete(String relativePath) async {
    final dir = await _dir();
    final file = File('${dir.path}/$relativePath');
    if (await file.exists()) await file.delete();
  }

  @override
  Future<String> absolutePathFor(String relativePath) async {
    final dir = await _dir();
    return '${dir.path}/$relativePath';
  }
}

/// In-memory fake for tests — no real disk I/O, no `path_provider`
/// platform channel.
class InMemoryOfflineFileStore implements OfflineFileStore {
  final Map<String, List<int>> _files = {};

  @override
  Future<void> writeBytes(String relativePath, List<int> bytes) async {
    _files[relativePath] = List.of(bytes);
  }

  @override
  Future<List<int>?> readBytes(String relativePath) async => _files[relativePath];

  @override
  Future<void> delete(String relativePath) async {
    _files.remove(relativePath);
  }

  @override
  Future<String> absolutePathFor(String relativePath) async => '/in-memory/$relativePath';
}

const _indexPath = 'index.json';

/// Reads/writes the offline-papers index as a plain JSON list — kept
/// separate from [OfflinePapersStore] so the encoding format has one
/// obvious owner.
class OfflineIndex {
  const OfflineIndex(this._store);
  final OfflineFileStore _store;

  Future<List<Map<String, dynamic>>> read() async {
    final bytes = await _store.readBytes(_indexPath);
    if (bytes == null) return [];
    final decoded = jsonDecode(utf8.decode(bytes)) as List;
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> write(List<Map<String, dynamic>> rows) async {
    await _store.writeBytes(_indexPath, utf8.encode(jsonEncode(rows)));
  }
}
