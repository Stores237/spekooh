import 'package:flutter/material.dart';
import '../../models/note.dart';
import '../../widgets/icon_chip.dart';

const mockNotes = [
  Note(title: 'Mechanics — Newton’s Laws', subtitle: 'Physics · A Level', tint: IconChipTint.blue, icon: Icons.bolt_outlined),
  Note(title: 'Cell Structure & Function', subtitle: 'Biology · O Level', tint: IconChipTint.green, icon: Icons.eco_outlined),
  Note(title: 'La Dissertation Philosophique', subtitle: 'Philosophie · Baccalauréat', tint: IconChipTint.purple, icon: Icons.menu_book_outlined),
  Note(title: 'Acids, Bases & Salts', subtitle: 'Chemistry · O Level', tint: IconChipTint.purple, icon: Icons.science_outlined),
  Note(title: 'Les Nombres Complexes', subtitle: 'Mathématiques · Terminale', tint: IconChipTint.blue, icon: Icons.functions),
];
