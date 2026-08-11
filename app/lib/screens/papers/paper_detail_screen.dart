import 'package:flutter/material.dart';
import '../../models/exam_taxonomy.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../../widgets/spekooh_badge.dart';
import '../../widgets/spekooh_button.dart';
import '../../widgets/spekooh_banner.dart';
import '../../widgets/stat_row.dart';
import 'papers_screen.dart';

/// Ported from ui_kits/spekooh-app/PaperDetailScreen.jsx. Pushed as a
/// full-screen overlay when a paper is tapped in PapersScreen's year list.
class PaperDetailScreen extends StatefulWidget {
  const PaperDetailScreen({super.key, this.paper});

  final PaperSelection? paper;

  @override
  State<PaperDetailScreen> createState() => _PaperDetailScreenState();
}

class _PaperDetailScreenState extends State<PaperDetailScreen> {
  bool _unlocked = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.paper;
    final title = p == null
        ? 'Physics — A Level 2025'
        : '${p.subject.title} — ${p.examType.name}${p.track != null ? ' ${p.track}' : ''} ${p.year}';
    final meta = p == null
        ? 'Secondary · Anglophone'
        : [p.category.title, if (p.system != null) (p.system == ExamSystem.francophone ? 'Francophone' : 'Anglophone')].join(' · ');

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(onTap: () => Navigator.of(context).pop(), child: const Padding(padding: EdgeInsets.only(top: 2), child: Icon(Icons.chevron_left))),
                  const SizedBox(width: AppSpacing.space2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary)),
                        Text(meta, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  if (p != null) SpekoohBadge(text: p.variant, tone: SpekoohBadgeTone.neutral),
                ],
              ),
              const SizedBox(height: AppSpacing.space4),
              Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.card),
                alignment: Alignment.center,
                child: Text('Question paper preview (scanned pages)', style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, color: AppColors.textTertiary)),
              ),
              const SizedBox(height: AppSpacing.space3),
              const StatRow(stats: [
                SpekoohStat(value: '8', label: 'questions'),
                SpekoohStat(value: '2', label: 'MCQ (in-house key)'),
                SpekoohStat(value: '2,341', label: 'views'),
              ]),
              const SizedBox(height: AppSpacing.space4),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.card),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Marking guide', style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                              Text('Instructor-authored + in-house MCQ key', style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        Icon(_unlocked ? Icons.lock_open : Icons.lock_outline, size: 18),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_unlocked)
                      Text('Unlocked — full solutions below.', style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, color: AppColors.green600, fontWeight: FontWeight.w600))
                    else
                      Row(
                        children: [
                          SpekoohButton(size: SpekoohButtonSize.sm, onPressed: () => setState(() => _unlocked = true), child: const Text('Unlock — 400 FCFA')),
                          const SizedBox(width: 12),
                          Text('Have a redeem code?', style: TextStyle(fontFamily: plusJakartaSansFamily, color: AppColors.gold700, fontWeight: FontWeight.w700, fontSize: 12)),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              SpekoohBanner(
                tone: SpekoohBannerTone.blue,
                icon: const Icon(Icons.info_outline),
                message: 'Objective/MCQ answers are marked in-house by the Spekooh review team, not the instructor.',
              ),
              const SizedBox(height: AppSpacing.space6),
            ],
          ),
        ),
      ),
    );
  }
}
