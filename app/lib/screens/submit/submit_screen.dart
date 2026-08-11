import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../../widgets/icon_chip.dart';
import '../../widgets/spekooh_banner.dart';
import '../../widgets/spekooh_button.dart';

enum _SubmitType { paper, report }

/// Ported from ui_kits/spekooh-app/SubmitScreen.jsx. One of the 5 bottom
/// tabs (the elevated center nav item). Form field values are static mock
/// display data (no real pickers yet) — matches the source, which used the
/// same hardcoded values.
class SubmitScreen extends StatefulWidget {
  const SubmitScreen({super.key});

  @override
  State<SubmitScreen> createState() => _SubmitScreenState();
}

class _SubmitScreenState extends State<SubmitScreen> {
  _SubmitType _type = _SubmitType.paper;
  int _step = 0;

  static const _paperFields = [
    ('Subject', 'Physics'),
    ('Education level', 'A-Level'),
    ('Exam type', 'GCE final'),
    ('Year', '2025'),
    ('Exam board / school (optional)', '—'),
  ];

  static const _reportFields = [
    ('Report type', 'Bachelor’s Report'),
    ('Discipline', 'Computer Science'),
    ('Institution', 'University of Buea'),
    ('Year', '2025'),
  ];

  @override
  Widget build(BuildContext context) {
    if (_step == 1) {
      return Scaffold(
        backgroundColor: AppColors.surfaceBg,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const IconChip(icon: Icons.check, tint: IconChipTint.green, size: 64),
                  const SizedBox(height: AppSpacing.space4),
                  Text('Contribution received', style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 19, color: AppColors.textPrimary)),
                  const SizedBox(height: AppSpacing.space2),
                  Text(
                    _type == _SubmitType.paper
                        ? "We'll check it against existing papers first — if it's new, it moves to instructor review. Track it under Profile."
                        : 'Thanks — academic reports are added straight to the library, browsable by discipline & year.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  SpekoohButton(onPressed: () => setState(() => _step = 0), child: const Text('Submit another')),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final fields = _type == _SubmitType.paper ? _paperFields : _reportFields;

    return Scaffold(
      backgroundColor: AppColors.surfaceBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.space2),
              Text('Contribution', style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text('Share a past paper or an academic report — every contribution helps another student.', style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.space4),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: AppColors.surfaceSunken, borderRadius: BorderRadius.circular(999)),
                child: Row(
                  children: [
                    Expanded(child: _typeTab('Exam paper', _SubmitType.paper)),
                    Expanded(child: _typeTab('Academic report', _SubmitType.report)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 26),
                decoration: BoxDecoration(
                  color: AppColors.gold50,
                  border: Border.all(color: AppColors.gold400, width: 1.5),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    const IconChip(icon: Icons.camera_alt_outlined, tint: IconChipTint.amber, size: 52),
                    const SizedBox(height: 8),
                    Text('Take a photo or upload a PDF', style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                    Text('JPG, PNG or PDF · up to 20MB', style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space5),
              Column(
                children: [
                  for (final (label, value) in fields) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(12), boxShadow: AppShadows.card),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(label, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, color: AppColors.textSecondary)),
                          Row(
                            children: [
                              Text(value, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
                              const SizedBox(width: 6),
                              const Icon(Icons.chevron_right, size: 14, color: AppColors.textTertiary),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space3),
                  ],
                ],
              ),
              SpekoohBanner(
                icon: const Icon(Icons.card_giftcard_outlined),
                message: _type == _SubmitType.paper
                    ? 'New, verified submissions earn bonus credit — redeemable toward marking-guide unlocks.'
                    : 'Academic reports are browsable references — no marking guide, but you still earn contributor credit.',
              ),
              const SizedBox(height: AppSpacing.space5),
              SizedBox(
                width: double.infinity,
                child: SpekoohButton(
                  onPressed: () => setState(() => _step = 1),
                  child: Text(_type == _SubmitType.paper ? 'Submit paper' : 'Submit report'),
                ),
              ),
              const SizedBox(height: AppSpacing.space6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeTab(String label, _SubmitType type) {
    final active = _type == type;
    return GestureDetector(
      onTap: () => setState(() => _type = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: active ? AppColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: active ? AppShadows.card : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: plusJakartaSansFamily,
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: active ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
