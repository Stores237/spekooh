import 'package:flutter/foundation.dart';

import '../models/marking_guide.dart';
import '../models/offline_guide.dart';
import 'offline_file_store.dart';

/// Saves/lists/removes marking guides for offline reading — same shape as
/// [OfflinePapersStore] (spec P1's "offline-saved" idea, extended to
/// corrections/marking guides per owner request, 2026-09-11), kept as its
/// own store rather than folding into OfflinePapersStore since a guide has
/// no binary file at all (see OfflineGuide's own doc comment) and the two
/// are shown as separate tabs (Papers/Corrections) on My Downloads.
class OfflineGuidesStore extends ChangeNotifier {
  OfflineGuidesStore({OfflineFileStore? fileStore})
      : _fileStore = fileStore ?? const LocalOfflineFileStore(subdirectory: 'offline_guides');

  static OfflineGuidesStore instance = OfflineGuidesStore();

  @visibleForTesting
  static void debugSetInstance(OfflineGuidesStore store) => instance = store;

  final OfflineFileStore _fileStore;
  late final OfflineIndex _index = OfflineIndex(_fileStore);

  List<OfflineGuide> _guides = [];

  /// Newest-saved first.
  List<OfflineGuide> get guides => List.unmodifiable(_guides);

  bool isSaved(int paperId) => _guides.any((g) => g.paperId == paperId);

  Future<void> bootstrap() async {
    final rows = await _index.read();
    _guides = rows.map(OfflineGuide.fromJson).toList()..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    notifyListeners();
  }

  Future<void> _persistIndex() async {
    await _index.write(_guides.map((g) => g.toJson()).toList());
  }

  /// Re-saving an already-saved guide just overwrites — no separate
  /// "update" path needed, same as OfflinePapersStore.save.
  Future<void> save({required int paperId, required String title, required MarkingGuide guide}) async {
    final entry = OfflineGuide(
      paperId: paperId,
      title: title,
      mcqAnswers: guide.mcqAnswers,
      nonMcqQuestions: guide.nonMcqQuestions,
      publishedAt: guide.publishedAt,
      savedAt: DateTime.now(),
    );
    _guides = [entry, ..._guides.where((g) => g.paperId != paperId)];
    await _persistIndex();
    notifyListeners();
  }

  Future<void> remove(int paperId) async {
    if (!_guides.any((g) => g.paperId == paperId)) return;
    _guides = _guides.where((g) => g.paperId != paperId).toList();
    await _persistIndex();
    notifyListeners();
  }
}
