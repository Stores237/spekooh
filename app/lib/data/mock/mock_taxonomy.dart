import '../../models/exam_taxonomy.dart';
import '../../models/subject.dart';
import '../../widgets/icon_chip.dart';
import '../../widgets/spekooh_badge.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Static exam-taxonomy lookup tables — sourced from
/// ui_kits/spekooh-app/PapersScreen.jsx. Composable fields (category ->
/// system -> examType -> track -> subject -> year) rather than fixed
/// per-exam screens, so a new exam type is a data row, not a code change.
class MockTaxonomy {
  MockTaxonomy._();

  static const categories = [
    ExamCategory(
      key: ExamCategoryKey.primary,
      title: 'Primary',
      icon: LucideIcons.baby,
      tint: IconChipTint.blue,
      subtitle: 'FSLC · CEP · Common Entrance',
    ),
    ExamCategory(
      key: ExamCategoryKey.secondary,
      title: 'Secondary',
      icon: LucideIcons.graduationCap,
      tint: IconChipTint.amber,
      subtitle: 'BEPC · Probatoire · Bac · O/A Level',
      requiresSystem: true,
    ),
    ExamCategory(
      key: ExamCategoryKey.university,
      title: 'University',
      icon: LucideIcons.landmark,
      tint: IconChipTint.blue,
      subtitle: 'Semester exams · Resits (State & Private)',
      requiresSystem: true,
    ),
    ExamCategory(
      key: ExamCategoryKey.tertiary,
      title: 'Tertiary',
      icon: LucideIcons.building2,
      tint: IconChipTint.green,
      subtitle: 'HND · BTS · AQP/CQP/DQP',
    ),
    ExamCategory(
      key: ExamCategoryKey.concours,
      title: 'Concours',
      icon: LucideIcons.trophy,
      tint: IconChipTint.purple,
      subtitle: 'ENAM · ENSP · UCAC · ESSEC & more',
    ),
    ExamCategory(
      key: ExamCategoryKey.reports,
      title: 'Academic Reports',
      icon: LucideIcons.bookOpen,
      tint: IconChipTint.red,
      subtitle: 'Internship · Mémoire · Thèse (no marking guide)',
    ),
  ];

  static const _primary = [
    ExamType(name: 'FSLC', subtitle: 'Anglophone'),
    ExamType(name: 'Common Entrance', subtitle: 'Anglophone'),
    ExamType(name: 'CEP', subtitle: 'Francophone', badgeTone: SpekoohBadgeTone.amber),
    ExamType(name: 'Concours d’Entrée en 6ème', subtitle: 'Francophone', badgeTone: SpekoohBadgeTone.amber),
  ];

  static const _secondaryFrancophone = [
    ExamType(
      name: 'BEPC',
      subtitle: '+ BEPC Blanc · Général/Technique',
      mockVariantLabel: 'BEPC Blanc',
      tracks: ['Général', 'Technique'],
      badgeTone: SpekoohBadgeTone.amber,
    ),
    ExamType(
      name: 'Probatoire',
      subtitle: '+ Probatoire Blanc · Général/Technique',
      mockVariantLabel: 'Probatoire Blanc',
      tracks: ['Général', 'Technique'],
      badgeTone: SpekoohBadgeTone.amber,
    ),
    ExamType(
      name: 'Baccalauréat',
      subtitle: '+ Bac Blanc · Général/Technique',
      mockVariantLabel: 'Bac Blanc',
      tracks: ['Général', 'Technique'],
      badgeTone: SpekoohBadgeTone.amber,
    ),
  ];

  static const _secondaryAnglophone = [
    ExamType(
      name: 'O Level',
      subtitle: '+ O Level Mock · General only',
      mockVariantLabel: 'O Level Mock',
      badgeTone: SpekoohBadgeTone.blue,
    ),
    ExamType(
      name: 'A Level',
      subtitle: '+ A Level Mock · Sci/Arts/Comm/Tech',
      mockVariantLabel: 'A Level Mock',
      tracks: ['Science', 'Arts', 'Commercial', 'Technical'],
      badgeTone: SpekoohBadgeTone.blue,
    ),
  ];

  static const _universityFrancophone = [
    ExamType(
      name: 'Examen Semestre 1',
      subtitle: '1er semestre, tous niveaux',
      tracks: ['L1', 'L2', 'L3', 'M1', 'M2'],
      badgeTone: SpekoohBadgeTone.amber,
    ),
    ExamType(
      name: 'Examen Semestre 2',
      subtitle: '2nd semestre, tous niveaux',
      tracks: ['L1', 'L2', 'L3', 'M1', 'M2'],
      badgeTone: SpekoohBadgeTone.amber,
    ),
    ExamType(
      name: 'Rattrapage',
      subtitle: 'Session de rattrapage',
      tracks: ['L1', 'L2', 'L3', 'M1', 'M2'],
      badgeTone: SpekoohBadgeTone.amber,
    ),
  ];

  static const _universityAnglophone = [
    ExamType(
      name: 'Semester 1 Exam',
      subtitle: '1st semester, all levels',
      tracks: ['L1', 'L2', 'L3', 'M1', 'M2'],
      badgeTone: SpekoohBadgeTone.blue,
    ),
    ExamType(
      name: 'Semester 2 Exam',
      subtitle: '2nd semester, all levels',
      tracks: ['L1', 'L2', 'L3', 'M1', 'M2'],
      badgeTone: SpekoohBadgeTone.blue,
    ),
    ExamType(
      name: 'Resit / Makeup',
      subtitle: 'Resit sittings',
      tracks: ['L1', 'L2', 'L3', 'M1', 'M2'],
      badgeTone: SpekoohBadgeTone.blue,
    ),
  ];

  static const _tertiary = [
    ExamType(name: 'HND', subtitle: 'Anglophone', badgeTone: SpekoohBadgeTone.blue),
    ExamType(name: 'BTS', subtitle: 'Francophone', badgeTone: SpekoohBadgeTone.amber),
    ExamType(name: 'AQP', subtitle: 'Vocational training center', badgeTone: SpekoohBadgeTone.green),
    ExamType(name: 'CQP', subtitle: 'Vocational training center', badgeTone: SpekoohBadgeTone.green),
    ExamType(name: 'DQP', subtitle: 'Vocational training center', badgeTone: SpekoohBadgeTone.green),
  ];

  static const _concours = [
    ExamType(name: 'ENAM', subtitle: 'École Nat. d’Administration'),
    ExamType(name: 'ENSP', subtitle: 'Polytechnique Yaoundé/Bamenda'),
    ExamType(name: 'ESSEC', subtitle: 'Douala / Garoua'),
    ExamType(name: 'UCAC', subtitle: 'Univ. Catholique d’Afrique Centrale'),
    ExamType(name: 'IUT', subtitle: 'Douala, Ngaoundéré & more'),
    ExamType(name: 'FMSB', subtitle: 'Médecine / Pharmacie'),
    ExamType(name: 'ENS', subtitle: 'Yaoundé / Bambili / Maroua'),
    ExamType(name: 'IAI', subtitle: 'Institut Africain d’Informatique'),
    ExamType(name: 'ESSTIC', subtitle: 'Info & Communication'),
    ExamType(name: 'EMIA', subtitle: 'Officer entrance'),
  ];

  // Mirrors backend apps/papers/migrations/0009_seed_report_exam_types.py —
  // same names, same order.
  static const _reports = [
    ExamType(name: 'Internship Report', subtitle: 'Year 1, Year 2', badgeTone: SpekoohBadgeTone.neutral),
    ExamType(name: 'Bachelor’s Report (Mémoire de Licence)', subtitle: 'Bachelor / Licence', badgeTone: SpekoohBadgeTone.neutral),
    ExamType(name: 'HND Report', subtitle: 'Rapport de fin d’études', badgeTone: SpekoohBadgeTone.neutral),
    ExamType(name: 'Master’s Thesis (Mémoire)', subtitle: 'Master', badgeTone: SpekoohBadgeTone.neutral, maxUploadMb: 50),
    ExamType(name: 'PhD Thesis (Thèse)', subtitle: 'Doctorat', badgeTone: SpekoohBadgeTone.neutral, maxUploadMb: 50),
  ];

  /// Mirrors examTypesByCat in the source: keyed by category, and by system
  /// too for the two categories that require one.
  static List<ExamType> examTypesFor(ExamCategoryKey category, ExamSystem? system) {
    switch (category) {
      case ExamCategoryKey.primary:
        return _primary;
      case ExamCategoryKey.secondary:
        return system == ExamSystem.francophone ? _secondaryFrancophone : _secondaryAnglophone;
      case ExamCategoryKey.university:
        return system == ExamSystem.francophone ? _universityFrancophone : _universityAnglophone;
      case ExamCategoryKey.tertiary:
        return _tertiary;
      case ExamCategoryKey.concours:
        return _concours;
      case ExamCategoryKey.reports:
        return _reports;
    }
  }

  static const subjectsEn = [
    Subject(key: 'accounting', title: 'Accounting', tint: IconChipTint.amber, icon: LucideIcons.fileText, code: '0505'),
    Subject(key: 'biology', title: 'Biology', tint: IconChipTint.green, icon: LucideIcons.leaf, code: '0510'),
    Subject(key: 'chemistry', title: 'Chemistry', tint: IconChipTint.purple, icon: LucideIcons.flaskConical, code: '0515'),
    Subject(key: 'computer_science', title: 'Computer science', tint: IconChipTint.blue, icon: LucideIcons.cpu, code: '0595'),
    Subject(key: 'economics', title: 'Economics', tint: IconChipTint.amber, icon: LucideIcons.trendingUp, code: '0525'),
    Subject(key: 'physics', title: 'Physics', tint: IconChipTint.blue, icon: LucideIcons.zap, code: '0580'),
  ];

  static const subjectsFr = [
    Subject(key: 'maths', title: 'Mathématiques', tint: IconChipTint.blue, icon: LucideIcons.sigma, code: 'MAT'),
    Subject(key: 'philo', title: 'Philosophie', tint: IconChipTint.purple, icon: LucideIcons.bookOpen, code: 'PHI'),
    Subject(key: 'hist_geo', title: 'Histoire-Géo', tint: IconChipTint.amber, icon: LucideIcons.globe, code: 'HGE'),
    Subject(key: 'svt', title: 'SVT', tint: IconChipTint.green, icon: LucideIcons.leaf, code: 'SVT'),
    Subject(key: 'physique_chimie', title: 'Physique-Chimie', tint: IconChipTint.blue, icon: LucideIcons.zap, code: 'PC'),
    Subject(key: 'anglais', title: 'Anglais', tint: IconChipTint.amber, icon: LucideIcons.globe, code: 'ANG'),
  ];

  static const _francophoneExamNames = {
    'BEPC', 'Probatoire', 'Baccalauréat', 'CEP', 'Concours d’Entrée en 6ème',
    'BTS', 'Examen Semestre 1', 'Examen Semestre 2', 'Rattrapage',
  };

  static List<Subject> subjectsForExamType(String examTypeName) {
    return _francophoneExamNames.contains(examTypeName) ? subjectsFr : subjectsEn;
  }
}
