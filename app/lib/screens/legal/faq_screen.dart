import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../common/circular_back_button.dart';
import 'faq_content.dart';

/// Reached from Settings' "FAQ" row (owner-requested, 2026-09-02). Every
/// answer is real — see faq_content.dart's own header for exactly what
/// backs each one. An accordion (collapsed by default, one tap to expand)
/// reads better than Privacy Policy's flat wall of text for genuinely
/// short question/answer pairs — several can stay collapsed at once, no
/// exclusivity, matching how most real FAQ pages behave.
class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final _expanded = <int>{};

  void _toggle(int index) => setState(() {
        if (!_expanded.add(index)) _expanded.remove(index);
      });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.surfaceBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.space2),
              Row(
                children: [
                  CircularBackButton(onTap: () => Navigator.of(context).pop()),
                  const SizedBox(width: AppSpacing.space3),
                  Text(l10n.helpFaqTitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 19, color: AppColors.textPrimary)),
                ],
              ),
              const SizedBox(height: AppSpacing.space4),
              for (var i = 0; i < faqEntries.length; i++) ...[
                _FaqTile(entry: faqEntries[i], expanded: _expanded.contains(i), onTap: () => _toggle(i)),
                const SizedBox(height: AppSpacing.space3),
              ],
              const SizedBox(height: AppSpacing.space3),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.entry, required this.expanded, required this.onTap});

  final FaqEntry entry;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.question,
                      style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 180),
                    turns: expanded ? 0.5 : 0,
                    child: const Icon(LucideIcons.chevronDown, size: 18, color: AppColors.textTertiary),
                  ),
                ],
              ),
              // AnimatedSize animates the height change; the answer itself
              // is only actually built (not just visually hidden) while
              // expanded — an AnimatedCrossFade here would keep both
              // states mounted for the transition, so a collapsed tile's
              // answer text would still exist in the tree.
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.topCenter,
                child: expanded
                    ? Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          entry.answer,
                          style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, height: 1.5, color: AppColors.textSecondary),
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
