import '../../../models/exam_taxonomy.dart';
import '../../../models/subject.dart';
import '../../../widgets/icon_chip.dart';
import '../../../widgets/spekooh_badge.dart';
import '../../api_client.dart';
import '../../icon_lookup.dart';
import '../../mock/mock_taxonomy.dart';
import '../papers_repository.dart';

/// Exam type names whose subjects are drawn from the French-language set —
/// ported directly from the same heuristic MockTaxonomy used (there's no
/// backend round-trip for this, just a fixed known-name check).
const _francophoneExamNames = {
  'BEPC', 'Probatoire', 'Baccalauréat', 'CEP', 'Concours d’Entrée en 6ème',
  'BTS', 'Examen Semestre 1', 'Examen Semestre 2', 'Rattrapage',
};

class HttpPapersRepository implements PapersRepository {
  HttpPapersRepository(this._client);
  final ApiClient _client;

  Map<ExamCategoryKey, int>? _categoryIdByKey;

  Future<Map<ExamCategoryKey, int>> _categoryIds() async {
    if (_categoryIdByKey != null) return _categoryIdByKey!;
    final rows = await _client.get('/papers/categories/') as List;
    final map = <ExamCategoryKey, int>{};
    for (final row in rows) {
      final key = ExamCategoryKey.values.byName(row['key'] as String);
      map[key] = row['id'] as int;
    }
    _categoryIdByKey = map;
    return map;
  }

  @override
  Future<List<ExamCategory>> getCategories() async {
    final rows = await _client.get('/papers/categories/') as List;
    final ids = <ExamCategoryKey, int>{};
    final categories = rows.map((row) {
      final key = ExamCategoryKey.values.byName(row['key'] as String);
      ids[key] = row['id'] as int;
      return ExamCategory(
        key: key,
        title: row['title'] as String,
        icon: iconForName(row['icon_name'] as String?),
        tint: IconChipTint.values.byName(row['tint'] as String? ?? 'blue'),
        subtitle: row['subtitle'] as String? ?? '',
        requiresSystem: row['requires_system'] as bool? ?? false,
      );
    }).toList();
    _categoryIdByKey = ids;
    return categories;
  }

  @override
  Future<List<ExamType>> getExamTypes(ExamCategoryKey category, ExamSystem? system) async {
    final ids = await _categoryIds();
    final categoryId = ids[category];
    if (categoryId == null) return const [];
    final query = <String, String>{'category': '$categoryId'};
    if (system != null) query['system'] = system.name;
    final rows = await _client.get('/papers/exam-types/', query: query) as List;
    return rows.map((row) {
      final tracks = (row['tracks'] as List?)?.map((t) => t as String).toList() ?? const [];
      return ExamType(
        name: row['name'] as String,
        subtitle: row['subtitle'] as String? ?? '',
        mockVariantLabel: (row['mock_variant_label'] as String?)?.isEmpty ?? true ? null : row['mock_variant_label'] as String,
        tracks: tracks.isEmpty ? null : tracks,
        badgeTone: SpekoohBadgeTone.values.byName(row['badge_tone'] as String? ?? 'neutral'),
      );
    }).toList();
  }

  @override
  Future<List<ReportType>> getReportTypes() => Future.value(MockTaxonomy.reportTypes);

  @override
  Future<List<Subject>> getSubjects(String examTypeName) async {
    final language = _francophoneExamNames.contains(examTypeName) ? 'fr' : 'en';
    final rows = await _client.get('/papers/subjects/', query: {'language': language}) as List;
    return rows.map((row) {
      return Subject(
        key: row['key'] as String,
        title: row['title'] as String,
        tint: IconChipTint.values.byName(row['tint'] as String? ?? 'blue'),
        icon: iconForName(row['icon_name'] as String?),
        code: row['code'] as String? ?? '',
      );
    }).toList();
  }
}
