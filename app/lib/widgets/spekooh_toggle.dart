import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// iOS-style switch used for quiz-setup options (Timer, Hints, Shuffle). On
/// = green-500 fill, off = light gray track, no built-in label. Ported from
/// components/forms/Toggle.jsx.
class SpekoohToggle extends StatelessWidget {
  const SpekoohToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.disabled = false,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final isDisabled = disabled || onChanged == null;
    return Opacity(
      opacity: isDisabled ? 0.5 : 1,
      child: GestureDetector(
        onTap: isDisabled ? null : () => onChanged!(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 44,
          height: 26,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: value ? AppColors.green500 : const Color(0xFFDADEE8),
            borderRadius: BorderRadius.circular(999),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Color(0x33000000), blurRadius: 3, offset: Offset(0, 1)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
