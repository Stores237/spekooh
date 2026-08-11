import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_radii.dart';
import '../theme/app_shadows.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';

enum SpekoohButtonVariant { primary, secondary, outline, ghost, dark }

enum SpekoohButtonSize { sm, md, lg }

/// Pill-shaped action button — the only button shape in Spekooh. Ported from
/// components/core/Button.jsx: shrinks slightly on press (no color change),
/// variants primary/secondary/outline/ghost/dark, sizes sm/md/lg.
class SpekoohButton extends StatefulWidget {
  const SpekoohButton({
    super.key,
    required this.child,
    this.variant = SpekoohButtonVariant.primary,
    this.size = SpekoohButtonSize.md,
    this.onPressed,
  });

  final Widget child;
  final SpekoohButtonVariant variant;
  final SpekoohButtonSize size;

  /// Null disables the button (matches the source's `disabled` prop).
  final VoidCallback? onPressed;

  bool get disabled => onPressed == null;

  @override
  State<SpekoohButton> createState() => _SpekoohButtonState();
}

class _SpekoohButtonState extends State<SpekoohButton> {
  bool _pressed = false;

  static const _sizePadding = {
    SpekoohButtonSize.sm: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    SpekoohButtonSize.md: EdgeInsets.symmetric(horizontal: 20, vertical: 13),
    SpekoohButtonSize.lg: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  };

  static const _sizeFontSize = {
    SpekoohButtonSize.sm: 13.0,
    SpekoohButtonSize.md: 15.0,
    SpekoohButtonSize.lg: 16.0,
  };

  @override
  Widget build(BuildContext context) {
    final disabled = widget.disabled;

    Color? bg;
    Gradient? gradient;
    Color textColor;
    Border? border;
    List<BoxShadow>? shadow;
    EdgeInsets padding = _sizePadding[widget.size]!;

    switch (widget.variant) {
      case SpekoohButtonVariant.primary:
        gradient = AppGradients.primary;
        textColor = AppColors.white;
        shadow = AppShadows.button;
      case SpekoohButtonVariant.secondary:
        bg = AppColors.blue100;
        textColor = AppColors.blue600;
      case SpekoohButtonVariant.outline:
        bg = Colors.transparent;
        textColor = AppColors.blue600;
        border = Border.all(color: AppColors.blue500, width: 1.5);
      case SpekoohButtonVariant.ghost:
        bg = Colors.transparent;
        textColor = AppColors.blue600;
        padding = const EdgeInsets.symmetric(horizontal: 0, vertical: 4);
      case SpekoohButtonVariant.dark:
        bg = AppColors.ink900;
        textColor = AppColors.white;
    }

    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: GestureDetector(
        onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: disabled ? null : () => setState(() => _pressed = false),
        onTap: disabled ? null : widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: padding,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              gradient: gradient,
              borderRadius: AppRadii.radiusPill,
              border: border,
              boxShadow: shadow,
            ),
            child: DefaultTextStyle.merge(
              style: TextStyle(
                fontFamily: plusJakartaSansFamily,
                fontWeight: AppTypography.bold,
                fontSize: _sizeFontSize[widget.size],
                color: textColor,
                height: 1.0,
              ),
              child: IconTheme.merge(
                data: IconThemeData(color: textColor, size: _sizeFontSize[widget.size]),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
