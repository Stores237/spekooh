import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Ported from ui_kits/spekooh-app/AIAssistant.jsx. A floating action
/// button, bottom-right above the bottom nav, shown only when logged in.
/// Opens a bottom sheet with suggested prompts + a text input.
class AIAssistantFab extends StatelessWidget {
  const AIAssistantFab({super.key});

  static List<String> _prompts(AppLocalizations l10n) => [
        l10n.aiPromptExplainPhysics,
        l10n.aiPromptMathsQuestions,
        l10n.aiPromptSummarizeGuide,
      ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const _AIAssistantSheet(),
      ),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.button),
        alignment: Alignment.center,
        child: const Icon(LucideIcons.sparkles, color: AppColors.white, size: 22),
      ),
    );
  }
}

class _AIAssistantSheet extends StatelessWidget {
  const _AIAssistantSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: AppShadows.sheet,
      ),
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.borderSubtle, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: AppSpacing.space4),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: const Icon(LucideIcons.sparkles, color: AppColors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.aiAssistantTitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary)),
                  Text(l10n.aiAssistantSubtitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space4),
          for (final prompt in AIAssistantFab._prompts(l10n)) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: AppColors.surfaceSunken, border: Border.all(color: AppColors.borderSubtle), borderRadius: BorderRadius.circular(12)),
              child: Text(prompt, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, color: AppColors.textPrimary)),
            ),
            const SizedBox(height: AppSpacing.space2),
          ],
          const SizedBox(height: AppSpacing.space2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: AppColors.surfaceSunken, border: Border.all(color: AppColors.borderSubtle), borderRadius: BorderRadius.circular(999)),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(hintText: l10n.aiAssistantInputHint, border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                    style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13),
                  ),
                ),
                const Icon(LucideIcons.send, size: 16, color: AppColors.gold700),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}
