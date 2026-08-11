import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/spekooh_avatar.dart';
import '../widgets/spekooh_badge.dart';
import '../widgets/spekooh_banner.dart';
import '../widgets/spekooh_button.dart';
import '../widgets/spekooh_toggle.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/icon_chip.dart';
import '../widgets/list_item_row.dart';
import '../widgets/search_input.dart';
import '../widgets/segmented_tabs.dart';
import '../widgets/stat_row.dart';
import '../widgets/subject_card.dart';

/// Debug-only "kitchen sink" screen — every design-system widget gets a
/// small preview here as it's built, for a quick visual diff against the
/// original ui_kits/spekooh-app screenshots. Not part of the real app
/// navigation graph (see shell/root_shell.dart once that exists); reachable
/// only as the temporary `home:` in main.dart during Stages 1-3.
///
/// Icons use Flutter's built-in Material Icons (outlined variants), not
/// Lucide as originally planned — the `lucide_icons` pub package subclasses
/// `IconData`, which became a `final` class in this Flutter SDK, so the
/// package fails to compile here. Material Icons is the guaranteed-
/// compatible fallback the plan itself named for this exact case.
class WidgetGalleryScreen extends StatefulWidget {
  const WidgetGalleryScreen({super.key});

  @override
  State<WidgetGalleryScreen> createState() => _WidgetGalleryScreenState();
}

class _WidgetGalleryScreenState extends State<WidgetGalleryScreen> {
  int _tab = 0;
  int _navActive = 0;
  bool _toggleOn = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Spekooh', style: AppTypography.displayStyle()),
              const SizedBox(height: AppSpacing.space1),
              Text('Widget gallery (debug)', style: AppTypography.bodyStyle()),
              const SizedBox(height: AppSpacing.space5),

              _section('Button'),
              Wrap(
                spacing: AppSpacing.space2,
                runSpacing: AppSpacing.space2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SpekoohButton(onPressed: () {}, child: const Text('Pay 500 FCFA')),
                  SpekoohButton(
                    variant: SpekoohButtonVariant.secondary,
                    onPressed: () {},
                    child: const Text('Open'),
                  ),
                  SpekoohButton(
                    variant: SpekoohButtonVariant.outline,
                    onPressed: () {},
                    child: const Text('Start quiz'),
                  ),
                  SpekoohButton(
                    variant: SpekoohButtonVariant.ghost,
                    size: SpekoohButtonSize.sm,
                    onPressed: () {},
                    child: const Text('Shop'),
                  ),
                  SpekoohButton(
                    variant: SpekoohButtonVariant.dark,
                    size: SpekoohButtonSize.sm,
                    onPressed: () {},
                    child: const Text('Create account'),
                  ),
                  const SpekoohButton(onPressed: null, child: Text('Disabled')),
                ],
              ),

              _section('Badge'),
              Wrap(
                spacing: AppSpacing.space2,
                runSpacing: AppSpacing.space2,
                children: const [
                  SpekoohBadge(text: 'Mock', tone: SpekoohBadgeTone.amber),
                  SpekoohBadge(text: 'Paper 2', tone: SpekoohBadgeTone.neutral),
                  SpekoohBadge(text: 'Verified', tone: SpekoohBadgeTone.green),
                  SpekoohBadge(text: 'Accounting', tone: SpekoohBadgeTone.blue),
                  SpekoohBadge(text: 'Sponsored', tone: SpekoohBadgeTone.dark),
                ],
              ),

              _section('IconChip'),
              Wrap(
                spacing: AppSpacing.space2,
                children: const [
                  IconChip(icon: Icons.functions, tint: IconChipTint.blue),
                  IconChip(icon: Icons.eco_outlined, tint: IconChipTint.green),
                  IconChip(icon: Icons.science_outlined, tint: IconChipTint.purple),
                  IconChip(icon: Icons.emoji_events_outlined, tint: IconChipTint.amber),
                  IconChip(icon: Icons.close, tint: IconChipTint.red),
                ],
              ),

              _section('Avatar'),
              Row(
                children: const [
                  SpekoohAvatar(name: 'Jojo B.', rank: 1),
                  SizedBox(width: AppSpacing.space4),
                  SpekoohAvatar(name: 'Julliete', rank: 2),
                  SizedBox(width: AppSpacing.space4),
                  SpekoohAvatar(name: 'Billionaire K.', rank: 3),
                ],
              ),

              _section('ListItemRow'),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    ListItemRow(
                      icon: const IconChip(icon: Icons.language_outlined, tint: IconChipTint.blue),
                      title: 'English',
                      trailing: const Icon(Icons.check, size: 18),
                    ),
                    const Divider(height: 1),
                    ListItemRow(
                      icon: const IconChip(icon: Icons.language_outlined, tint: IconChipTint.blue),
                      title: 'Français',
                    ),
                  ],
                ),
              ),

              _section('StatRow'),
              const StatRow(stats: [
                SpekoohStat(value: '15', label: 'questions'),
                SpekoohStat(value: '8 min', label: 'suggested'),
                SpekoohStat(value: '5564', label: 'played'),
              ]),

              _section('SubjectCard'),
              Row(
                children: [
                  Expanded(
                    child: SubjectCard(
                      icon: const IconChip(icon: Icons.eco_outlined, tint: IconChipTint.green),
                      title: 'Biology',
                      subtitle: 'Past papers by year',
                      badgeText: 'Papers',
                      code: '0510',
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: SubjectCard(
                      icon: const IconChip(icon: Icons.science_outlined, tint: IconChipTint.purple),
                      title: 'Chemistry',
                      subtitle: 'Past papers by year',
                      badgeText: 'Papers',
                      code: '0515',
                      onTap: () {},
                    ),
                  ),
                ],
              ),

              _section('Banner'),
              Column(
                children: [
                  SpekoohBanner(
                    icon: const Icon(Icons.download_outlined),
                    message: 'Saved papers open without internet — even in the village.',
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  SpekoohBanner(
                    tone: SpekoohBannerTone.blue,
                    icon: const Icon(Icons.auto_awesome_outlined),
                    message: 'Summarize with Spekooh Bot',
                  ),
                ],
              ),

              _section('SearchInput'),
              const SearchInput(placeholder: 'Search 20 subjects...'),

              _section('Toggle'),
              Row(
                children: [
                  SpekoohToggle(value: _toggleOn, onChanged: (v) => setState(() => _toggleOn = v)),
                  const SizedBox(width: AppSpacing.space4),
                  SpekoohToggle(value: false, onChanged: (_) {}),
                ],
              ),

              _section('SegmentedTabs'),
              SegmentedTabs(
                options: const ['All', 'Sciences', 'Arts', 'Commercial'],
                active: _tab,
                onChanged: (i) => setState(() => _tab = i),
              ),

              _section('BottomNav'),
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: BottomNav(
                  active: _navActive,
                  onChanged: (i) => setState(() => _navActive = i),
                  items: const [
                    SpekoohNavItem(icon: Icon(Icons.home_outlined), label: 'Home'),
                    SpekoohNavItem(icon: Icon(Icons.description_outlined), label: 'Papers'),
                    SpekoohNavItem(icon: Icon(Icons.auto_awesome_outlined), center: true),
                    SpekoohNavItem(icon: Icon(Icons.chat_bubble_outline), label: 'Forum'),
                    SpekoohNavItem(icon: Icon(Icons.bolt_outlined), label: 'Quizzes'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.space5, bottom: AppSpacing.space3),
      child: Text(title, style: AppTypography.h3Style()),
    );
  }
}
