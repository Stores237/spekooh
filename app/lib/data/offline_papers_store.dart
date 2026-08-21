import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/offline_paper.dart';
import 'offline_file_store.dart';

/// Thrown when [OfflinePapersStore.save] has nothing to download — the
/// paper has no scanned file yet (see [PaperEntry.fileUrl]).
class NoOfflineFileAvailableError implements Exception {
  const NoOfflineFileAvailableError();
}

/// Saves/lists/removes papers for offline access (spec P1 "offline-saved
/// papers for later access"), mobile-only per the product decision — no
/// meaningful `path_provider` implementation exists for web, and this
/// isn't the ship target anyway (spec §6).
///
/// Downloads a paper's real scanned file to on-device storage and keeps a
/// small on-device index so the file survives app restarts and can be
/// listed/opened without a network connection.
class OfflinePapersStore extends ChangeNotifier {
  OfflinePapersStore({OfflineFileStore? fileStore, Future<List<int>> Function(String url)? download})
      : _fileStore = fileStore ?? const LocalOfflineFileStore(),
        _download = download ?? _httpDownload;

  static OfflinePapersStore instance = OfflinePapersStore();

  @visibleForTesting
  static void debugSetInstance(OfflinePapersStore store) => instance = store;

  final OfflineFileStore _fileStore;
  final Future<List<int>> Function(String url) _download;
  late final OfflineIndex _index = OfflineIndex(_fileStore);

  List<OfflinePaper> _papers = [];

  /// Newest-saved first.
  List<OfflinePaper> get papers => List.unmodifiable(_papers);

  bool isSaved(int paperId) => _papers.any((p) => p.paperId == paperId);

  OfflinePaper? _find(int paperId) => _papers.cast<OfflinePaper?>().firstWhere((p) => p!.paperId == paperId, orElse: () => null);

  Future<void> bootstrap() async {
    final rows = await _index.read();
    _papers = rows.map(OfflinePaper.fromJson).toList()..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    notifyListeners();
  }

  Future<void> _persistIndex() async {
    await _index.write(_papers.map((p) => p.toJson()).toList());
  }

  /// Downloads [fileUrl] and saves it under [paperId] with the given
  /// display [title]/[subtitle]. Re-saving an already-saved paper just
  /// re-downloads and overwrites — no separate "update" path needed.
  Future<void> save({
    required int paperId,
    required String title,
    required String subtitle,
    required String? fileUrl,
  }) async {
    if (fileUrl == null) throw const NoOfflineFileAvailableError();
    final bytes = await _download(fileUrl);
    final relativePath = '$paperId${_extensionOf(fileUrl)}';
    await _fileStore.writeBytes(relativePath, bytes);

    final entry = OfflinePaper(paperId: paperId, title: title, subtitle: subtitle, relativeFilePath: relativePath, savedAt: DateTime.now());
    _papers = [entry, ..._papers.where((p) => p.paperId != paperId)];
    await _persistIndex();
    notifyListeners();
  }

  Future<void> remove(int paperId) async {
    final existing = _find(paperId);
    if (existing == null) return;
    await _fileStore.delete(existing.relativeFilePath);
    _papers = _papers.where((p) => p.paperId != paperId).toList();
    await _persistIndex();
    notifyListeners();
  }

  /// A real, openable path for an already-saved paper — null if it was
  /// never saved (callers should check [isSaved] first).
  Future<String?> absolutePathFor(int paperId) async {
    final existing = _find(paperId);
    if (existing == null) return null;
    return _fileStore.absolutePathFor(existing.relativeFilePath);
  }

  static String _extensionOf(String url) {
    final path = Uri.parse(url).path;
    final dot = path.lastIndexOf('.');
    return dot == -1 ? '' : path.substring(dot);
  }

  static Future<List<int>> _httpDownload(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw http.ClientException('Download failed: HTTP ${response.statusCode}', Uri.parse(url));
    }
    return response.bodyBytes;
  }
}
