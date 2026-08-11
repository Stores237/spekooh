import 'package:flutter/material.dart';

/// Ported 1:1 from tokens/shadows.css. The shadow tints (rgba(24,36,81,...)
/// for card/sheet, rgba(63,95,219,...) for button) are leftover cool-navy
/// values from before the gold rework — kept verbatim since that's the
/// literal value in the source token file, not "fixed" here.
class AppShadows {
  AppShadows._();

  static const card = [
    BoxShadow(color: Color(0x0A182451), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(color: Color(0x0F182451), offset: Offset(0, 4), blurRadius: 14),
  ];

  static const cardHover = [
    BoxShadow(color: Color(0x0F182451), offset: Offset(0, 2), blurRadius: 4),
    BoxShadow(color: Color(0x17182451), offset: Offset(0, 8), blurRadius: 20),
  ];

  static const sheet = [
    BoxShadow(color: Color(0x2E182451), offset: Offset(0, -8), blurRadius: 30),
  ];

  static const button = [
    BoxShadow(color: Color(0x473F5FDB), offset: Offset(0, 4), blurRadius: 12),
  ];
}
