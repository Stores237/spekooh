import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// One real country today (Cameroon — the only one MTN MoMo/Orange Money
/// charges actually work against here), architecturally ready for more
/// without overpromising support that doesn't exist yet.
class _Country {
  const _Country({required this.flag, required this.dialCode, required this.name});
  final String flag;
  final String dialCode;
  final String name;
}

const _countries = [_Country(flag: '🇨🇲', dialCode: '+237', name: 'Cameroon')];

/// Real MTN MoMo/Orange Money number entry (owner-provided reference,
/// 2026-09-11) — a real, tappable country-code selector (flag + dial code
/// + chevron) instead of a fixed "+237" Text, and "XXX XX XX XX" as the
/// placeholder pattern instead of a real-looking example number. Shared by
/// PaywallSheet, PamphletSheet, and PaperDetailScreen's two unlock cards,
/// which all used to duplicate this exact field inline.
class PhoneNumberField extends StatefulWidget {
  const PhoneNumberField({super.key, required this.controller, this.error});

  final TextEditingController controller;
  final String? error;

  @override
  State<PhoneNumberField> createState() => _PhoneNumberFieldState();
}

class _PhoneNumberFieldState extends State<PhoneNumberField> {
  _Country _country = _countries.first;

  Future<void> _pickCountry() async {
    final picked = await showModalBottomSheet<_Country>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final country in _countries)
              ListTile(
                leading: Text(country.flag, style: const TextStyle(fontSize: 20)),
                title: Text(country.name),
                trailing: Text(country.dialCode),
                onTap: () => Navigator.of(context).pop(country),
              ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _country = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.momoOrangeLabel, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.4)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: AppColors.white, border: Border.all(color: AppColors.borderSubtle), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              GestureDetector(
                key: const Key('phoneCountryPicker'),
                onTap: _pickCountry,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_country.flag, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Text(_country.dialCode, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const SizedBox(width: 2),
                    const Icon(LucideIcons.chevronDown, size: 14, color: AppColors.textTertiary),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(width: 1, height: 20, color: AppColors.borderSubtle),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(hintText: 'XXX XX XX XX', border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                  style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
        if (widget.error != null) ...[
          const SizedBox(height: 6),
          Text(widget.error!, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.red500)),
        ],
      ],
    );
  }
}
