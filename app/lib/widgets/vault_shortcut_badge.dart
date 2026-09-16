import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_shadows.dart';
import '../theme/app_theme.dart';

/// The "QR Vault" shortcut card on Profile, sitting beside the bonus credit
/// balance card as its own separate pink card (owner correction, 2026-09-16
/// — an earlier version overlaid this as a small badge on top of the bonus
/// card; the owner asked for two distinct cards instead, same row layout as
/// the Home screen's Daily Challenge / Start-quiz pair). No IconChipTint
/// matches the reference's pink/magenta -- this is a one-off card, not a
/// new shared tint added to that enum for a single use.
class VaultShortcutBadge extends StatelessWidget {
  const VaultShortcutBadge({super.key, required this.onTap});
  final VoidCallback onTap;

  static const _bg = Color(0xFFFBDCEF);
  static const _fg = Color(0xFFD6247A);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.card),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(color: _fg, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const Icon(LucideIcons.lock, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.qrVaultShortcutLabel,
              style: const TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 13, color: _fg),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
