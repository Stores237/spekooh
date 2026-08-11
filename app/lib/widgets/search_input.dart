import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_theme.dart';

/// Full-width pill search field, sits at the top of list/browse screens.
/// Ported from components/forms/SearchInput.jsx.
class SearchInput extends StatelessWidget {
  const SearchInput({
    super.key,
    this.placeholder,
    this.controller,
    this.onChanged,
    this.icon,
  });

  final String? placeholder;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: AppRadii.radiusPill,
      ),
      child: Row(
        children: [
          icon ?? const Icon(Icons.search, size: 16, color: AppColors.textTertiary),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: TextStyle(
                  fontFamily: plusJakartaSansFamily,
                  fontSize: 14,
                  color: AppColors.textTertiary,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(
                fontFamily: plusJakartaSansFamily,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
