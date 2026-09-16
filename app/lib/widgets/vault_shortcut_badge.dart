import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// The "Vault" shortcut to QR Vault (owner-provided reference image,
/// 2026-09-16), placed in the top-right corner of the bonus credit balance
/// card on Profile (owner-annotated screenshot pinpointing that exact
/// spot). No IconChipTint matches the reference's pink/magenta -- this is a
/// one-off badge, not a new shared tint added to that enum for a single use.
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: _bg, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const Icon(LucideIcons.lock, color: _fg, size: 20),
          ),
          const SizedBox(height: 4),
          Text(l10n.qrVaultShortcutLabel, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 11, color: Colors.white)),
        ],
      ),
    );
  }
}
