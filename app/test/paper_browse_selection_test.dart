import 'package:flutter_test/flutter_test.dart';
import 'package:spekooh/models/exam_taxonomy.dart';
import 'package:spekooh/data/mock/mock_taxonomy.dart';

void main() {
  group('PaperBrowseSelection', () {
    test('starts at category step', () {
      const sel = PaperBrowseSelection();
      expect(sel.currentStep, PaperBrowseStep.category);
    });

    test('category requiring a system moves to system step', () {
      final secondary = MockTaxonomy.categories.firstWhere((c) => c.key == ExamCategoryKey.secondary);
      final sel = const PaperBrowseSelection().selectCategory(secondary);
      expect(sel.currentStep, PaperBrowseStep.system);
    });

    test('category not requiring a system skips straight to examType step', () {
      final primary = MockTaxonomy.categories.firstWhere((c) => c.key == ExamCategoryKey.primary);
      final sel = const PaperBrowseSelection().selectCategory(primary);
      expect(sel.currentStep, PaperBrowseStep.examType);
    });

    test('exam type requiring a track moves to track step; others skip to subject', () {
      final secondary = MockTaxonomy.categories.firstWhere((c) => c.key == ExamCategoryKey.secondary);
      final aLevel = MockTaxonomy.examTypesFor(ExamCategoryKey.secondary, ExamSystem.anglophone)
          .firstWhere((t) => t.name == 'A Level');
      final oLevel = MockTaxonomy.examTypesFor(ExamCategoryKey.secondary, ExamSystem.anglophone)
          .firstWhere((t) => t.name == 'O Level');

      final withTrack = const PaperBrowseSelection()
          .selectCategory(secondary)
          .selectSystem(ExamSystem.anglophone)
          .selectExamType(aLevel);
      expect(withTrack.currentStep, PaperBrowseStep.track);

      final withoutTrack = const PaperBrowseSelection()
          .selectCategory(secondary)
          .selectSystem(ExamSystem.anglophone)
          .selectExamType(oLevel);
      expect(withoutTrack.currentStep, PaperBrowseStep.subject);
    });

    test('reaches paperList once subject is picked', () {
      final primary = MockTaxonomy.categories.firstWhere((c) => c.key == ExamCategoryKey.primary);
      final fslc = MockTaxonomy.examTypesFor(ExamCategoryKey.primary, null).firstWhere((t) => t.name == 'FSLC');
      final sel = const PaperBrowseSelection()
          .selectCategory(primary)
          .selectExamType(fslc)
          .selectSubject('accounting');
      expect(sel.currentStep, PaperBrowseStep.paperList);
    });

    test('stepBack clears exactly the last-set field, not earlier ones', () {
      final secondary = MockTaxonomy.categories.firstWhere((c) => c.key == ExamCategoryKey.secondary);
      final aLevel = MockTaxonomy.examTypesFor(ExamCategoryKey.secondary, ExamSystem.anglophone)
          .firstWhere((t) => t.name == 'A Level');
      final full = const PaperBrowseSelection()
          .selectCategory(secondary)
          .selectSystem(ExamSystem.anglophone)
          .selectExamType(aLevel)
          .selectTrack('Science')
          .selectSubject('physics');

      final afterOneBack = full.stepBack();
      expect(afterOneBack.subjectKey, isNull);
      expect(afterOneBack.track, 'Science');

      final afterTwoBack = afterOneBack.stepBack();
      expect(afterTwoBack.track, isNull);
      expect(afterTwoBack.examType, isNotNull);

      final afterThreeBack = afterTwoBack.stepBack();
      expect(afterThreeBack.examType, isNull);
      expect(afterThreeBack.system, isNotNull);

      final afterFourBack = afterThreeBack.stepBack();
      expect(afterFourBack.system, isNull);
      expect(afterFourBack.category, isNotNull);

      final afterFiveBack = afterFourBack.stepBack();
      expect(afterFiveBack.category, isNull);
      expect(afterFiveBack.currentStep, PaperBrowseStep.category);
    });
  });
}
