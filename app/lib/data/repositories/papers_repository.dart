import '../../models/exam_taxonomy.dart';
import '../../models/subject.dart';
import '../mock/mock_taxonomy.dart';

abstract class PapersRepository {
  Future<List<ExamCategory>> getCategories();
  Future<List<ExamType>> getExamTypes(ExamCategoryKey category, ExamSystem? system);
  Future<List<ReportType>> getReportTypes();
  Future<List<Subject>> getSubjects(String examTypeName);
}

class MockPapersRepository implements PapersRepository {
  @override
  Future<List<ExamCategory>> getCategories() => Future.value(MockTaxonomy.categories);

  @override
  Future<List<ExamType>> getExamTypes(ExamCategoryKey category, ExamSystem? system) =>
      Future.value(MockTaxonomy.examTypesFor(category, system));

  @override
  Future<List<ReportType>> getReportTypes() => Future.value(MockTaxonomy.reportTypes);

  @override
  Future<List<Subject>> getSubjects(String examTypeName) =>
      Future.value(MockTaxonomy.subjectsForExamType(examTypeName));
}
