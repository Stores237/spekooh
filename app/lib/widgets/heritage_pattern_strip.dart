import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A repeating diamond motif — a quiet nod to West African textile border
/// patterns (owner reference, 2026-09-12: a real kente/mud-cloth-style
/// border screenshot, plus a mockup of it applied to this app's own splash
/// screen).
///
/// Deliberately not a literal reproduction of the reference — that source
/// pattern is a dense, four-row, high-contrast band (interlocking rope
/// rows, alternating triangles/diamonds, a dotted row) in its own
/// red/cream/gold palette. The owner's own instruction alongside it:
/// "less presence... just a representation... not the app design itself
/// ...not aggressive." So this keeps only the simplest single motif from
/// it (the small diamond-with-a-center-dot row — the quietest of the
/// four), rendered once and thin, in this app's own existing gold tones.
///
/// Follow-up, 2026-09-14 (owner: "still not polished... more living and
/// modern... not too aggressive, no over saturating"): the original,
/// [HeritagePatternStrip.new] default — 16% opacity, this app's cream
/// [AppColors.surfaceBg] behind it, pinned to the very bottom of the whole
/// screen — was so faint against a low-contrast background that it read as
/// nothing at all, not as "quiet." Confirmed live: invisible at a real
/// mobile viewport. Rather than raise the default (breaking the ceiling
/// this widget was built to guarantee — see the widget's own test), this
/// adds [HeritagePatternStrip.onDark] for the app's own ink900 card
/// surfaces, where the reference image's actual relationship (dark ground,
/// gold-and-red embroidery) has real contrast to work with. Two-tone
/// (alternating gold/red, both already this app's own tokens) restores the
/// "woven trim" read the single-gold-tone version lost — still just a thin
/// stroked outline, not a solid block, so it stays a trim, not a banner.
class HeritagePatternStrip extends StatelessWidget {
  const HeritagePatternStrip({super.key, this.height = 22, this.opacity = 0.16})
      : primaryColor = AppColors.gold700,
        accentColor = null;

  /// For this app's own dark ink900 card surfaces (Home's greeting header,
  /// Quizzes' leaderboard) — real presence instead of the default's
  /// near-invisible cream-background version, plus a second tone
  /// (AppColors.red500, already in this app's own palette) alternating
  /// with gold for the two-tone woven-trim look.
  const HeritagePatternStrip.onDark({super.key, this.height = 16, this.opacity = 0.6})
      : primaryColor = AppColors.gold400,
        accentColor = AppColors.red500;

  final double height;
  final double opacity;
  final Color primaryColor;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(painter: _DiamondRowPainter(primaryColor, accentColor)),
      ),
    );
  }
}

class _DiamondRowPainter extends CustomPainter {
  _DiamondRowPainter(this.primaryColor, this.accentColor);

  final Color primaryColor;
  final Color? accentColor;

  // A fixed real-world size (not size-dependent) so the motif reads at
  // the same physical scale on any device — a repeating pattern that
  // stretched to fill an arbitrary width would look different on every
  // screen size, which a real textile border never does.
  static const _cellWidth = 30.0;

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final diamondHalfWidth = _cellWidth * 0.3;
    final diamondHalfHeight = size.height * 0.4;

    var i = 0;
    var cx = _cellWidth / 2;
    while (cx < size.width + _cellWidth) {
      final color = (accentColor != null && i.isOdd) ? accentColor! : primaryColor;
      final outline = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;
      final dot = Paint()..color = color;

      final path = Path()
        ..moveTo(cx, centerY - diamondHalfHeight)
        ..lineTo(cx + diamondHalfWidth, centerY)
        ..lineTo(cx, centerY + diamondHalfHeight)
        ..lineTo(cx - diamondHalfWidth, centerY)
        ..close();
      canvas.drawPath(path, outline);
      canvas.drawCircle(Offset(cx, centerY), 1.6, dot);

      cx += _cellWidth;
      i++;
    }
  }

  @override
  bool shouldRepaint(covariant _DiamondRowPainter oldDelegate) =>
      oldDelegate.primaryColor != primaryColor || oldDelegate.accentColor != accentColor;
}
