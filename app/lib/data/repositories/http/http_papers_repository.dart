import '../../../models/exam_taxonomy.dart';
import '../../../models/paper_entry.dart';
import '../../../models/subject.dart';
import '../../../widgets/icon_chip.dart';
import '../../../widgets/spekooh_badge.dart';
import '../../api_client.dart';
import '../../icon_lookup.dart';
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
        id: row['id'] as int,
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
        id: row['id'] as int,
        name: row['name'] as String,
        subtitle: row['subtitle'] as String? ?? '',
        mockVariantLabel: (row['mock_variant_label'] as String?)?.isEmpty ?? true ? null : row['mock_variant_label'] as String,
        tracks: tracks.isEmpty ? null : tracks,
        badgeTone: SpekoohBadgeTone.values.byName(row['badge_tone'] as String? ?? 'neutral'),
      );
    }).toList();
  }

  @override
  Future<List<Subject>> getSubjects(String examTypeName) async {
    final language = _francophoneExamNames.contains(examTypeName) ? 'fr' : 'en';
    final rows = await _client.get('/papers/subjects/', query: {'language': language}) as List;
    return rows.map((row) {
      return Subject(
        id: row['id'] as int,
        key: row['key'] as String,
        title: row['title'] as String,
        tint: IconChipTint.values.byName(row['tint'] as String? ?? 'blue'),
        icon: iconForName(row['icon_name'] as String?),
        code: row['code'] as String? ?? '',
      );
    }).toList();
  }

  PaperEntry _paperFromJson(Map<String, dynamic> row) => PaperEntry(
        id: row['id'] as int,
        year: row['year'] as int,
        system: row['system'] as String?,
        track: row['track'] as String? ?? '',
        status: row['status'] as String,
        fileUrl: row['file_url'] as String?,
        createdAt: DateTime.tryParse(row['created_at'] as String? ?? ''),
        examBoard: row['exam_board'] as String? ?? '',
        subjectTitle: row['subject_title'] as String?,
        examTypeName: row['exam_type_name'] as String?,
        institution: row['institution'] as String? ?? '',
        discipline: row['discipline'] as String? ?? '',
        supervisorName: row['supervisor_name'] as String? ?? '',
      );

  @override
  Future<PaperEntry> getPaperDetail(int paperId) async {
    final row = await _client.get('/papers/submissions/$paperId/');
    return _paperFromJson(row as Map<String, dynamic>);
  }

  @override
  Future<PaperEntry?> getLatestPublished() async {
    final rows = await _client.get('/papers/submissions/', query: {
      'status': 'PUBLISHED',
      'ordering': '-created_at',
    }) as List;
    if (rows.isEmpty) return null;
    return _paperFromJson(rows.first as Map<String, dynamic>);
  }

  @override
  Future<List<PaperEntry>> getPapers({
    required int categoryId,
    required int examTypeId,
    int? subjectId,
    ExamSystem? system,
    String? track,
  }) async {
    final query = <String, String>{
      'category': '$categoryId',
      'exam_type': '$examTypeId',
      'status': 'PUBLISHED',
    };
    if (subjectId != null) query['subject'] = '$subjectId';
    if (system != null) query['system'] = system.name;
    if (track != null && track.isNotEmpty) query['track'] = track;
    final rows = await _client.get('/papers/submissions/', query: query) as List;
    return rows.map((row) => _paperFromJson(row as Map<String, dynamic>)).toList();
  }

  @override
  Future<PaperEntry> submitPaper({
    required int categoryId,
    required int examTypeId,
    int? subjectId,
    ExamSystem? system,
    String? track,
    required int year,
    String examBoard = '',
    String institution = '',
    String discipline = '',
    String supervisorName = '',
    required SubmissionFile file,
  }) async {
    final fields = <String, String>{
      'category': '$categoryId',
      'exam_type': '$examTypeId',
      'year': '$year',
      'exam_board': examBoard,
    };
    if (subjectId != null) fields['subject'] = '$subjectId';
    if (system != null) fields['system'] = system.name;
    if (track != null && track.isNotEmpty) fields['track'] = track;
    if (institution.isNotEmpty) fields['institution'] = institution;
    if (discipline.isNotEmpty) fields['discipline'] = discipline;
    if (supervisorName.isNotEmpty) fields['supervisor_name'] = supervisorName;

    final row = await _client.postMultipart(
      '/papers/submissions/',
      fileFieldName: 'uploaded_file',
      fileBytes: file.bytes,
      fileName: file.fileName,
      mimeType: file.mimeType,
      fields: fields,
    );
    return _paperFromJson(row as Map<String, dynamic>);
  }

  @override
  Future<void> recordView(int paperId) async {
    try {
      await _client.post('/papers/submissions/$paperId/view/');
    } on ApiException catch (e) {
      if (e.statusCode == 402) throw const PaywallException();
      rethrow;
    }
  }

  @override
  Future<void> recordAdWatch() async {
    await _client.post('/papers/ad-watch/');
  }

  @override
  Future<int> unlockPaper(int paperId, {String? redeemCode}) async {
    final row = await _client.post('/payments/unlock/', body: {
      'paper_submission': paperId,
      'phone_number': '000000000',
      if (redeemCode != null && redeemCode.isNotEmpty) 'redeem_code': redeemCode,
    });
    return row['amount_paid'] as int;
  }

  @override
  Future<void> reportPaper(int paperId, {required String reason, String details = ''}) async {
    try {
      await _client.post('/papers/submissions/$paperId/report/', body: {
        'reason': reason,
        if (details.isNotEmpty) 'details': details,
      });
    } on ApiException catch (e) {
      if (e.statusCode == 409) throw const AlreadyReportedException();
      rethrow;
    }
  }
}
