import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_radii.dart';
import '../theme/app_shadows.dart';
import '../theme/app_theme.dart';

class SpekoohNavItem {
  const SpekoohNavItem({required this.icon, this.label, this.center = false});
  final Widget icon;
  final String? label;

  /// The center item ("AI Assistant" tab) renders as a visually-elevated
  /// gold-gradient rounded square that pokes above the bar, distinct from
  /// the flat icon+label tabs either side.
  final bool center;
}

/// Bottom tab bar — 4 flat icon+label tabs plus one elevated center item.
/// Ported from components/navigation/BottomNav.jsx.
class BottomNav extends StatelessWidget {
  const BottomNav({super.key, required this.items, required this.active, required this.onChanged});

  final List<SpekoohNavItem> items;
  final int active;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < items.length; i++)
            _NavButton(
              item: items[i],
              isActive: i == active,
              onTap: () => onChanged(i),
            ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.item, required this.isActive, required this.onTap});

  final SpekoohNavItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (item.center) {
      return GestureDetector(
        onTap: onTap,
        child: Transform.translate(
          offset: const Offset(0, -24),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppGradients.bot,
              borderRadius: AppRadii.radiusLg,
              boxShadow: AppShadows.button,
            ),
            alignment: Alignment.center,
            child: IconTheme.merge(
              data: const IconThemeData(color: AppColors.white),
              child: item.icon,
            ),
          ),
        ),
      );
    }
    final color = isActive ? AppColors.blue600 : AppColors.textTertiary;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconTheme.merge(data: IconThemeData(color: color, size: 22), child: item.icon),
          if (item.label != null) ...[
            const SizedBox(height: 3),
            Text(
              item.label!,
              style: TextStyle(
                fontFamily: plusJakartaSansFamily,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
