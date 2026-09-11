import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_radii.dart';
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

/// Real notch radius around the center button (owner-provided reference,
/// 2026-09-11 — "the semi circle spacing"): noticeably larger than the
/// button's own 26px radius so a visible gap shows between the button and
/// the bar's own cut edge, not a snug/touching fit.
const _notchRadius = 38.0;

/// The bar's real total height (10px top padding + 52px content row + 14px
/// bottom padding — measured live via a widget test, not eyeballed).
/// Scaffold normally reserves exactly this much space above
/// bottomNavigationBar automatically; RootShell instead sets extendBody so
/// real page content can show through the notch's transparent cut-out
/// (owner, 2026-09-11: "it has to be transparent, that is we could see
/// what is behind" — not just free of a shadow tint, but an actual hole
/// through to the screen behind it), which means it has to add this same
/// amount back itself so that content isn't hidden under the bar's own
/// opaque parts.
const kBottomNavHeight = 76.0;

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

    final content = Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
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

    if (centerIndex == -1) {
      // Nothing to cut a notch around — the plain flat bar this always was.
      return Container(
        decoration: const BoxDecoration(color: AppColors.white, border: Border(top: BorderSide(color: AppColors.borderSubtle))),
        child: content,
      );
    }

    // The center button paints on top, unclipped (see _NavButton) — only
    // the bar's own background+border are cut into a notch here, via a
    // CustomPainter rather than a plain BoxDecoration border, since a
    // curved edge can't be expressed as a Border side. Real Flutter Material
    // shape (CircularNotchedRectangle), the same one BottomAppBar/
    // FloatingActionButton normally rely on — not a hand-rolled curve.
    //
    // CustomPaint(painter:, child:) rather than a Stack: sized by `content`
    // (its child) with no ambiguity, and hit-testing naturally reaches
    // `content`'s own buttons — a Stack here (Positioned.fill background +
    // a plain-sized `content` sibling) was found live to silently swallow
    // the center button's taps, likely from the two children resolving
    // their bounds independently in a way real content stopped receiving
    // pointer events at its own visual position.
    return CustomPaint(
      painter: _NotchedBarPainter(),
      child: content,
    );
  }
}

class _NotchedBarPainter extends CustomPainter {
  const _NotchedBarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final host = Rect.fromLTWH(0, 0, size.width, size.height);
    // dy: 12 — matches the real button's own resting center (10px content
    // padding + 26px half-height, translated up 24px by _NavButton: see
    // its own comment). CircularNotchedRectangle's algorithm takes an
    // arbitrary guest.center, not just one sitting exactly on host.top, so
    // this can match the button's real, hit-test-safe position rather
    // than moving the button to match an idealized notch-centered-on-the-
    // edge assumption (found live: pushing the button further up to sit
    // exactly on that edge moved it far enough outside Scaffold's own
    // bottomNavigationBar hit-test bounds that taps stopped registering,
    // even though it kept painting fine, unclipped, the whole time).
    final guest = Rect.fromCircle(center: Offset(size.width / 2, 12), radius: _notchRadius);
    final path = const CircularNotchedRectangle().getOuterPath(host, guest);
    canvas.drawPath(path, Paint()..color = AppColors.white);
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.borderSubtle
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _NotchedBarPainter oldDelegate) => false;
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
              // Owner-requested (2026-09-11): fully circular, not the
              // rounded square every other icon chip in this app uses —
              // this is the one deliberately different shape, matching a
              // provided reference image.
              borderRadius: AppRadii.radiusPill,
              // No boxShadow here (unlike every other AppShadows.button use):
              // the notch's cut-out gap around this button is meant to be
              // fully transparent — AppShadows.button's leftover navy-blue
              // tint (see app_shadows.dart) painted a visible blue halo into
              // that gap instead (owner screenshot, 2026-09-11).
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
