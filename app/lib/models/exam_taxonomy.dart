import 'package:flutter/material.dart';
import '../widgets/icon_chip.dart';
import '../widgets/spekooh_badge.dart';

/// Top-level browse category. `reports` is a distinct content type (no
/// marking guide / instructor routing) handled separately by the screen.
enum ExamCategoryKey { primary, secondary, university, tertiary, concours, reports }

enum ExamSystem { francophone, anglophone }

class ExamCategory {
  const ExamCategory({
    this.id = 0,
    required this.key,
    required this.title,
    required this.icon,
    required this.tint,
    required this.subtitle,
    this.requiresSystem = false,
  });

  /// Real backend primary key — 0 for the static mock/report-type entries
  /// that have no backend row (see ReportType, which is never sent to the API).
  final int id;
  final ExamCategoryKey key;
  final String title;
  final IconData icon;
  final IconChipTint tint;
  final String subtitle;
  final bool requiresSystem;
}

class ExamType {
  const ExamType({
    this.id = 0,
    required this.name,
    required this.subtitle,
    this.mockVariantLabel,
    this.tracks,
    this.badgeTone = SpekoohBadgeTone.neutral,
  });

  final int id;
  final String name;
  final String subtitle;

  /// e.g. "BEPC Blanc" — null means official-only, no mock/blanc variant.
  final String? mockVariantLabel;

  /// null means this exam type has no track sub-step (e.g. FSLC).
  final List<String>? tracks;

  final SpekoohBadgeTone badgeTone;

  bool get requiresTrack => tracks != null && tracks!.isNotEmpty;
}

class ReportType {
  const ReportType({required this.key, required this.title, required this.subtitle});
  final String key;
  final String title;
  final String subtitle;
}

/// Which step of the Papers drill-down is showing, derived purely from what
/// has been selected so far (see PaperBrowseSelection.currentStep) — never
/// tracked as separate state, so it can't drift out of sync with the
/// selection itself.
enum PaperBrowseStep { category, system, examType, track, subject, paperList }

@immutable
class PaperBrowseSelection {
  const PaperBrowseSelection({
    this.category,
    this.system,
    this.examType,
    this.track,
    this.subjectKey,
  });

  final ExamCategory? category;
  final ExamSystem? system;
  final ExamType? examType;
  final String? track;
  final String? subjectKey;

  PaperBrowseSelection copyWith({
    ExamCategory? category,
    ExamSystem? system,
    ExamType? examType,
    String? track,
    String? subjectKey,
  }) {
    return PaperBrowseSelection(
      category: category ?? this.category,
      system: system ?? this.system,
      examType: examType ?? this.examType,
      track: track ?? this.track,
      subjectKey: subjectKey ?? this.subjectKey,
    );
  }

  /// Selecting a category clears everything downstream; selecting a system
  /// clears examType/track/subject; etc. Always returns a fresh instance.
  PaperBrowseSelection selectCategory(ExamCategory c) => PaperBrowseSelection(category: c);
  PaperBrowseSelection selectSystem(ExamSystem s) => PaperBrowseSelection(category: category, system: s);
  PaperBrowseSelection selectExamType(ExamType t) =>
      PaperBrowseSelection(category: category, system: system, examType: t);
  PaperBrowseSelection selectTrack(String t) =>
      PaperBrowseSelection(category: category, system: system, examType: examType, track: t);
  PaperBrowseSelection selectSubject(String key) => copyWith(subjectKey: key);

  /// Clears the last-set field in priority order (subject > track > examType
  /// > system > category) — the generic "step back" the back-chevron calls.
  PaperBrowseSelection stepBack() {
    if (subjectKey != null) {
      return PaperBrowseSelection(category: category, system: system, examType: examType, track: track);
    }
    if (track != null) {
      return PaperBrowseSelection(category: category, system: system, examType: examType);
    }
    if (examType != null) {
      return PaperBrowseSelection(category: category, system: system);
    }
    if (system != null) {
      return PaperBrowseSelection(category: category);
    }
    return const PaperBrowseSelection();
  }

  PaperBrowseStep get currentStep {
    if (category == null) return PaperBrowseStep.category;
    if (category!.requiresSystem && system == null) return PaperBrowseStep.system;
    if (examType == null) return PaperBrowseStep.examType;
    if (examType!.requiresTrack && track == null) return PaperBrowseStep.track;
    if (subjectKey == null) return PaperBrowseStep.subject;
    return PaperBrowseStep.paperList;
  }
}
