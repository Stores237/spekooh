import 'package:flutter/material.dart';

/// Maps the icon_name strings the backend stores (ported 1:1 from the
/// original Icons.* names used when the taxonomy/notes seed data was
/// authored) back to real IconData for display. Icons aren't otherwise
/// portable over JSON, so this is the deliberate seam.
const Map<String, IconData> iconByName = {
  'child_care_outlined': Icons.child_care_outlined,
  'school_outlined': Icons.school_outlined,
  'account_balance_outlined': Icons.account_balance_outlined,
  'business_outlined': Icons.business_outlined,
  'emoji_events_outlined': Icons.emoji_events_outlined,
  'menu_book_outlined': Icons.menu_book_outlined,
  'description_outlined': Icons.description_outlined,
  'eco_outlined': Icons.eco_outlined,
  'science_outlined': Icons.science_outlined,
  'memory_outlined': Icons.memory_outlined,
  'trending_up_outlined': Icons.trending_up_outlined,
  'bolt_outlined': Icons.bolt_outlined,
  'functions': Icons.functions,
  'public_outlined': Icons.public_outlined,
  'language_outlined': Icons.language_outlined,
};

IconData iconForName(String? name, {IconData fallback = Icons.circle_outlined}) =>
    iconByName[name] ?? fallback;
