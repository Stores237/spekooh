import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Maps the icon_name strings the backend stores (ported 1:1 from the
/// original Icons.* names used when the taxonomy/notes seed data was
/// authored) back to real IconData for display. Icons aren't otherwise
/// portable over JSON, so this is the deliberate seam.
const Map<String, IconData> iconByName = {
  'child_care_outlined': LucideIcons.baby,
  'school_outlined': LucideIcons.graduationCap,
  'account_balance_outlined': LucideIcons.landmark,
  'business_outlined': LucideIcons.building2,
  'emoji_events_outlined': LucideIcons.trophy,
  'menu_book_outlined': LucideIcons.bookOpen,
  'description_outlined': LucideIcons.fileText,
  'eco_outlined': LucideIcons.leaf,
  'science_outlined': LucideIcons.flaskConical,
  'memory_outlined': LucideIcons.cpu,
  'trending_up_outlined': LucideIcons.trendingUp,
  'bolt_outlined': LucideIcons.zap,
  'functions': LucideIcons.sigma,
  'public_outlined': LucideIcons.globe,
  'language_outlined': LucideIcons.globe,
};

IconData iconForName(String? name, {IconData fallback = LucideIcons.circle}) =>
    iconByName[name] ?? fallback;
