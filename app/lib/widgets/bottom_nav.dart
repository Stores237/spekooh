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
    // Previously one flat Row with MainAxisAlignment.spaceBetween — with
    // French labels ("Accueil"/"Épreuves" on the left running noticeably
    // wider than "Forum"/"Quiz" on the right), spaceBetween's equal-gap
    // distribution put more real content before the center button than
    // after it, visibly pushing it right of center (found from a live
    // screenshot, 2026-08-28). Splitting the flanking tabs into their own
    // two Expanded halves — each spread independently around the fixed-
    // width center button — keeps the button at the true geometric middle
    // no matter how wide either side's labels are, in any locale.
    final centerIndex = items.indexWhere((i) => i.center);
    // No item marked center: everything falls into "before" and this
    // degrades to one plain, evenly-spread row (Expanded + spaceAround) —
    // still correct, just without a raised middle button.
    final before = List.generate(centerIndex == -1 ? items.length : centerIndex, (i) => i);
    final after = centerIndex == -1 ? const <int>[] : List.generate(items.length - centerIndex - 1, (i) => centerIndex + 1 + i);

    Widget navButton(int i) => _NavButton(
          item: items[i],
          isActive: i == active,
          onTap: () => onChanged(i),
        );

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: before.map(navButton).toList(),
            ),
          ),
          if (centerIndex != -1) navButton(centerIndex),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: after.map(navButton).toList(),
            ),
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
