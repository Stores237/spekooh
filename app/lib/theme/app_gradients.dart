import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Ported 1:1 from tokens/colors.css — all four gradients are stops along
/// the same gold ramp (135deg diagonal, top-left to bottom-right).
class AppGradients {
  AppGradients._();

  static const primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.gold400, AppColors.gold700],
  );

  static const bot = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.gold200, AppColors.gold600],
  );

  static const goldSoft = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.gold50, AppColors.gold200],
  );

  static const goldDeep = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.gold500, AppColors.gold700],
  );
}
