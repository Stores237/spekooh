import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/house_ad_visibility.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_theme.dart';
import 'icon_chip.dart';

/// Kawlo's own house ad recruiting new advertisers (owner-provided
/// reference, 2026-09-11) — distinct from the sponsor/promotion section
/// elsewhere on Home, which shows OTHER businesses' ads TO users; this one
/// is Kawlo pitching advertising slots TO businesses. Copy is deliberately
/// generic ("your business"), not "your school" — the owner's own point:
/// this app doesn't only advertise schools (S@Learn, the first real
/// sponsor, is a tutor-matching platform, not a school). Real WhatsApp
/// contact on tap (same number as Settings' own support channel), and a
/// real, persisted dismiss — see HouseAdVisibility's own comment on why
/// TokenStorage rather than a new dependency.
class HouseAdCard extends StatefulWidget {
  const HouseAdCard({super.key});

  @override
  State<HouseAdCard> createState() => _HouseAdCardState();
}

class _HouseAdCardState extends State<HouseAdCard> {
  static const _supportWhatsapp = '237659802679';

  late final Future<bool> _dismissedFuture = HouseAdVisibility.instance.isDismissed();
  bool? _dismissedOverride;

  Future<void> _dismiss() async {
    await HouseAdVisibility.instance.dismiss();
    if (mounted) setState(() => _dismissedOverride = true);
  }

  Future<void> _contact(AppLocalizations l10n) async {
    final ok = await launchUrl(Uri.parse('https://wa.me/$_supportWhatsapp'), mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.couldNotOpenLink)));
    }
  }

  void _showWhyThisAd(AppLocalizations l10n) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.houseAdExplanation, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13)),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<bool>(
      future: _dismissedFuture,
      builder: (context, snapshot) {
        // No flash of a card that's about to disappear: nothing renders
        // until the real dismissed-state check resolves, and nothing
        // renders at all once dismissed (this run's tap or a past one).
        if (snapshot.connectionState != ConnectionState.done) return const SizedBox.shrink();
        if (_dismissedOverride ?? snapshot.data ?? false) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.card),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.surfaceSunken, borderRadius: BorderRadius.circular(999)),
                    child: Text(l10n.houseAdSponsoredLabel, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.4)),
                  ),
                  GestureDetector(
                    key: const Key('houseAdDismissButton'),
                    onTap: _dismiss,
                    child: const Icon(LucideIcons.x, size: 18, color: AppColors.textTertiary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _contact(l10n),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const IconChip(icon: LucideIcons.trophy, tint: IconChipTint.amber, size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.houseAdTitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary)),
                          const SizedBox(height: 2),
                          Text(l10n.houseAdSubtitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    const Icon(LucideIcons.chevronRight, color: AppColors.textTertiary),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _showWhyThisAd(l10n),
                child: Text(l10n.houseAdWhyThisAd, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textTertiary)),
              ),
            ],
          ),
        );
      },
    );
  }
}
