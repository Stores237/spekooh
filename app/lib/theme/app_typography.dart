import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Ported 1:1 from tokens/typography.css — Plus Jakarta Sans, sizes/weights
/// matching the CSS custom properties exactly.
class AppTypography {
  AppTypography._();

  static const double display = 28;
  static const double h1 = 22;
  static const double h2 = 19;
  static const double h3 = 17;
  static const double body = 15;
  static const double bodySm = 13;
  static const double caption = 11;

  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semibold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extrabold = FontWeight.w800;

  static const double leadingTight = 1.2;
  static const double leadingNormal = 1.4;
  static const double leadingRelaxed = 1.55;
  static const double trackingCaption = 0.06;

  static TextStyle _style({
    required double size,
    required FontWeight weight,
    double? height,
    double? letterSpacing,
    Color color = AppColors.textPrimary,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing != null ? letterSpacing * size : null,
      color: color,
    );
  }

  static TextStyle displayStyle({Color color = AppColors.textPrimary}) =>
      _style(size: display, weight: extrabold, height: leadingTight, color: color);
  static TextStyle h1Style({Color color = AppColors.textPrimary}) =>
      _style(size: h1, weight: bold, height: leadingTight, color: color);
  static TextStyle h2Style({Color color = AppColors.textPrimary}) =>
      _style(size: h2, weight: bold, height: leadingTight, color: color);
  static TextStyle h3Style({Color color = AppColors.textPrimary}) =>
      _style(size: h3, weight: semibold, height: leadingTight, color: color);
  static TextStyle bodyStyle({Color color = AppColors.textPrimary, FontWeight? weight}) =>
      _style(size: body, weight: weight ?? regular, height: leadingNormal, color: color);
  static TextStyle bodySmStyle({Color color = AppColors.textSecondary, FontWeight? weight}) =>
      _style(size: bodySm, weight: weight ?? regular, height: leadingNormal, color: color);
  static TextStyle captionStyle({Color color = AppColors.textTertiary}) => _style(
        size: caption,
        weight: semibold,
        height: leadingNormal,
        letterSpacing: trackingCaption,
        color: color,
      );
}
