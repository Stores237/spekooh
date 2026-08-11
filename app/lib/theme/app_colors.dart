import 'package:flutter/material.dart';

/// Ported 1:1 from tokens/colors.css. Legacy `blue`/`amber` names are kept
/// (matching the CSS token names) but alias into the gold family per the
/// source tokens — Spekooh has one primary interactive color (gold), not a
/// separate blue.
class AppColors {
  AppColors._();

  // Ink (near-black brown) — primary text / dark surfaces.
  static const ink900 = Color(0xFF241A08);
  static const ink800 = Color(0xFF362610);
  static const ink700 = Color(0xFF4A3418);

  // Gold ramp — the one primary/interactive color.
  static const gold50 = Color(0xFFFBF3E1);
  static const gold200 = Color(0xFFEFCD83);
  static const gold400 = Color(0xFFE2A52A);
  static const gold500 = Color(0xFFC8881C);
  static const gold600 = Color(0xFFA8721A);
  static const gold700 = Color(0xFF835611);

  // Legacy blue/amber aliases (tokens/colors.css aliases these to gold).
  static const blue600 = gold500;
  static const blue500 = gold400;
  static const blue400 = gold400;
  static const blue100 = gold50;
  static const blue50 = gold50;
  static const amber600 = gold700;
  static const amber500 = gold500;
  static const amber100 = gold200;
  static const amber50 = gold50;

  // Semantic accents.
  static const green600 = Color(0xFF4C7A34);
  static const green500 = Color(0xFF6FA23A);
  static const green100 = Color(0xFFEAF1D9);
  static const purple600 = Color(0xFF7D5474);
  static const purple500 = Color(0xFFA6709B);
  static const purple100 = Color(0xFFF1E4EE);
  static const red500 = Color(0xFFD1603C);
  static const red100 = Color(0xFFFBE3D8);

  static const white = Color(0xFFFFFFFF);

  // Surfaces / borders.
  static const surfaceBg = Color(0xFFF7F4EE);
  static const surfaceCard = Color(0xFFFFFFFF);
  static const surfaceSunken = Color(0xFFFBF8F2);
  static const borderSubtle = Color(0xFFEAE2D2);

  // Text.
  static const textPrimary = ink900;
  static const textSecondary = Color(0xFF6B6155);
  static const textTertiary = Color(0xFF9C9184);
  static const textOnDark = Color(0xFFFFFFFF);
  static const textOnDarkMuted = Color(0xFFD9C79A);

  // Links / accents.
  static const link = gold700;
  static const linkHover = ink900;
  static const accentPrimary = gold500;
  static const accentWarn = gold500;
  static const accentSuccess = green500;
  static const accentDanger = red500;
}
