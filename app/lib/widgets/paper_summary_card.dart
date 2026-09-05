import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/repositories/papers_repository.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import 'spekooh_button.dart';

/// AI-generated summary of a paper's own extracted text (apps.ai on the
/// backend, Phase 1 — Gemini, cron-generated, cached per paper).
///
/// Only meant to be shown for a paper the caller can already view — see
/// PaperDetailScreen's own `locked` gate, which mirrors
/// apps.papers.services.user_can_view_file exactly (same field:
/// PaperEntry.requiresUnlock), the same check
/// apps.ai.views.PaperSummaryView applies server-side. This widget never
/// needs to render a paywall state of its own because of that.
///
/// Renders nothing at all (SizedBox.shrink()) once it's established there's
/// no summary to show right now — AI_ENABLED off, the backend 404s, or a
/// genuine network failure (including, in tests, a fake repository that
/// doesn't implement this method at all). This is a nice-to-have
/// enhancement, not core enough to justify an error state cluttering the
/// paper detail screen or breaking it outright.
class PaperSummaryCard extends StatefulWidget {
  const PaperSummaryCard({super.key, required this.paperId, required this.repository});
  final int paperId;
  final PapersRepository repository;

  @override
  State<PaperSummaryCard> createState() => _PaperSummaryCardState();
}

class _PaperSummaryCardState extends State<PaperSummaryCard> {
  PaperSummaryResult? _result;
  bool _loading = true;
  bool _hidden = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    PaperSummaryResult? result;
    try {
      result = await widget.repository.getPaperSummary(widget.paperId);
    } catch (_) {
      // Never let an optional summary block or crash this screen — same
      // reasoning as PaperDetailScreen._recordView's own catch-all.
      result = null;
    }
    if (!mounted) return;
    setState(() {
      _result = result;
      _loading = false;
      _hidden = result == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hidden) return const SizedBox.shrink();
    // First load still in flight — nothing to show yet, and no spinner of
    // its own either: the main file card above already has one.
    if (_loading && _result == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final result = _result!;
    final ready = result.status == PaperSummaryStatus.ready && (result.body?.trim().isNotEmpty ?? false);

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.space3),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.sparkles, size: 16, color: AppColors.gold700),
              const SizedBox(width: 8),
              Text(l10n.aiSummaryTitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 10),
          if (ready) ...[
            Text(result.body!.trim(), style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, height: 1.5, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text(l10n.aiSummaryDisclaimer, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 10.5, color: AppColors.textTertiary)),
          ] else ...[
            Row(
              children: [
                const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    result.status == PaperSummaryStatus.failed ? l10n.aiSummaryFailed : l10n.aiSummaryGenerating,
                    style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SpekoohButton(
              size: SpekoohButtonSize.sm,
              onPressed: _loading ? null : _load,
              child: Text(l10n.aiSummaryCheckAgain),
            ),
          ],
        ],
      ),
    );
  }
}
