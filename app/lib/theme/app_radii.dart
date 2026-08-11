import 'package:flutter/material.dart';

/// Ported 1:1 from tokens/radius.css.
class AppRadii {
  AppRadii._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 18;
  static const double xl = 22;
  static const double pill = 999;
  static const double chip = 12;

  static const radiusSm = BorderRadius.all(Radius.circular(sm));
  static const radiusMd = BorderRadius.all(Radius.circular(md));
  static const radiusLg = BorderRadius.all(Radius.circular(lg));
  static const radiusXl = BorderRadius.all(Radius.circular(xl));
  static const radiusPill = BorderRadius.all(Radius.circular(pill));
  static const radiusChip = BorderRadius.all(Radius.circular(chip));
}
