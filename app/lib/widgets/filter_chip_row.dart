import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_theme.dart';

/// A single-select horizontal chip row with a leading "All" option — reused
/// across NotesScreen (Subject, Academic level) and ShopScreen (same pair).
/// [selected] null means "All".
class FilterChipRow extends StatelessWidget {
  const FilterChipRow({super.key, required this.label, required this.options, required this.selected, required this.onSelected});

  final String label;
  final List<String> options;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = <String?>[null, ...options];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.6)),
        const SizedBox(height: 6),
        SizedBox(
          height: 32,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final value = items[i];
              final active = value == selected;
              return GestureDetector(
                onTap: () => onSelected(value),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: active ? AppColors.ink900 : AppColors.white,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: active ? null : AppShadows.card,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    value ?? l10n.filterAll,
                    style: TextStyle(
                      fontFamily: plusJakartaSansFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: active ? AppColors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
