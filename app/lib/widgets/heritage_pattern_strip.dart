import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A thin, low-opacity repeating diamond motif — a single, quiet nod to
/// West African textile border patterns (owner reference, 2026-09-12:
/// a real kente/mud-cloth-style border screenshot, plus a mockup of it
/// applied to this app's own splash screen).
///
/// Deliberately not a literal reproduction of the reference — that source
/// pattern is a dense, four-row, high-contrast band (interlocking rope
/// rows, alternating triangles/diamonds, a dotted row) in its own
/// red/cream/gold palette. The owner's own instruction alongside it:
/// "less presence... just a representation... not the app design itself
/// ...not aggressive." So this keeps only the simplest single motif from
/// it (the small diamond-with-a-center-dot row — the quietest of the
/// four), rendered once, thin, in this app's own existing gold tones
/// (not the reference's own reds/creams, which would look like a
/// mismatched sticker rather than something that belongs here), and at
/// low opacity — a background texture, not a foreground border.
class HeritagePatternStrip extends StatelessWidget {
  const HeritagePatternStrip({super.key, this.height = 22, this.opacity = 0.16});

  final double height;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(painter: _DiamondRowPainter()),
      ),
    );
  }
}

class _DiamondRowPainter extends CustomPainter {
  // A fixed real-world size (not size-dependent) so the motif reads at
  // the same physical scale on any device — a repeating pattern that
  // stretched to fill an arbitrary width would look different on every
  // screen size, which a real textile border never does.
  static const _cellWidth = 34.0;

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Paint()
      ..color = AppColors.gold700
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final dot = Paint()..color = AppColors.gold700;

    final centerY = size.height / 2;
    final diamondHalfWidth = _cellWidth * 0.3;
    final diamondHalfHeight = size.height * 0.32;

    var cx = _cellWidth / 2;
    while (cx < size.width + _cellWidth) {
      final path = Path()
        ..moveTo(cx, centerY - diamondHalfHeight)
        ..lineTo(cx + diamondHalfWidth, centerY)
        ..lineTo(cx, centerY + diamondHalfHeight)
        ..lineTo(cx - diamondHalfWidth, centerY)
        ..close();
      canvas.drawPath(path, outline);
      canvas.drawCircle(Offset(cx, centerY), 1.6, dot);
      cx += _cellWidth;
    }
  }

  @override
  bool shouldRepaint(covariant _DiamondRowPainter oldDelegate) => false;
}
