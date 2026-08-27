import '../../models/note.dart';
import '../../widgets/icon_chip.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const mockNotes = [
  Note(title: 'Mechanics: Newton’s Laws', subtitle: 'Physics · A Level', tint: IconChipTint.blue, icon: LucideIcons.zap),
  Note(title: 'Cell Structure & Function', subtitle: 'Biology · O Level', tint: IconChipTint.green, icon: LucideIcons.leaf),
  Note(title: 'La Dissertation Philosophique', subtitle: 'Philosophie · Baccalauréat', tint: IconChipTint.purple, icon: LucideIcons.bookOpen),
  Note(title: 'Acids, Bases & Salts', subtitle: 'Chemistry · O Level', tint: IconChipTint.purple, icon: LucideIcons.flaskConical),
  Note(title: 'Les Nombres Complexes', subtitle: 'Mathématiques · Terminale', tint: IconChipTint.blue, icon: LucideIcons.sigma),
];
