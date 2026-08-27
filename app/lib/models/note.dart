import 'package:flutter/material.dart';
import '../widgets/icon_chip.dart';

class Note {
  const Note({
    this.id = 0,
    required this.title,
    required this.subtitle,
    required this.tint,
    required this.icon,
    this.subjectTitle = '',
    this.academicLevel = '',
  });
  final int id;
  final String title;
  final String subtitle;
  final IconChipTint tint;
  final IconData icon;

  /// Backs the Subject/Academic level filter chips on NotesScreen — kept
  /// separate from [subtitle] (still the single "Subject · Level" display
  /// string) so filtering doesn't depend on parsing display text.
  final String subjectTitle;
  final String academicLevel;
}
