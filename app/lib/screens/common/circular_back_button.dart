import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// The small circular chevron-left back button reused at the top of most
/// pushed screens (Notes, Notifications, Shop, Profile, ...).
class CircularBackButton extends StatelessWidget {
  const CircularBackButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.white,
          border: Border.all(color: AppColors.borderSubtle),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.chevron_left, size: 20, color: AppColors.textPrimary),
      ),
    );
  }
}
