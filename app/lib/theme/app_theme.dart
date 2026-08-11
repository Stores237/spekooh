import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Assembles the token layers (app_colors, app_typography, app_radii,
/// app_spacing, app_shadows, app_gradients) into a Flutter ThemeData.
/// Individual widgets mostly reach for the token classes directly (this
/// design system uses bespoke widgets, not stock Material components), but
/// ThemeData still needs to be sane for text selection, scrollbars, etc.
final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: AppColors.surfaceBg,
  fontFamily: plusJakartaSansFamily,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.gold500,
    primary: AppColors.gold500,
    secondary: AppColors.gold700,
    surface: AppColors.surfaceCard,
    error: AppColors.red500,
    brightness: Brightness.light,
  ),
  textTheme: TextTheme(
    displayLarge: AppTypography.displayStyle(),
    headlineLarge: AppTypography.h1Style(),
    headlineMedium: AppTypography.h2Style(),
    headlineSmall: AppTypography.h3Style(),
    bodyLarge: AppTypography.bodyStyle(),
    bodyMedium: AppTypography.bodySmStyle(color: AppColors.textPrimary),
    labelSmall: AppTypography.captionStyle(),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.surfaceBg,
    foregroundColor: AppColors.textPrimary,
    elevation: 0,
    surfaceTintColor: Colors.transparent,
  ),
  dividerTheme: const DividerThemeData(
    color: AppColors.borderSubtle,
    thickness: 1,
    space: 1,
  ),
);

/// google_fonts resolves the actual family string lazily; this constant
/// name documents intent but the real font is applied per-TextStyle via
/// AppTypography (GoogleFonts.plusJakartaSans(...)) since GoogleFonts'
/// ThemeData-level `textTheme` helper conflicts with our custom TextTheme
/// above. Kept as a plain string fallback for widgets outside our TextTheme.
const String plusJakartaSansFamily = 'Plus Jakarta Sans';
