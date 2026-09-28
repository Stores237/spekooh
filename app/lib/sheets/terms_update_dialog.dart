import 'package:flutter/material.dart';
import '../data/repositories/profile_repository.dart';
import '../l10n/app_localizations.dart';
import '../screens/legal/terms_of_service_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/spekooh_button.dart';

/// Asks a signed-in user to accept the current Terms of Service. Shown by the
/// root shell when the server says this account has no recorded acceptance of
/// the current version (see apps.accounts.services.needs_terms_acceptance).
///
/// Deliberately blocking: no barrier tap, no back gesture. The only ways out
/// are to accept or to log out, so nobody keeps using an account under Terms
/// they were never shown. Agreement needs an explicit tick, not just a tap on
/// "Accept", and the Terms are one tap away before deciding.
class TermsUpdateDialog extends StatefulWidget {
  const TermsUpdateDialog({super.key, required this.version, required this.repository, required this.onLogout});

  /// The version the user is shown; sent back so the server records agreement
  /// to exactly this text.
  final String version;
  final ProfileRepository repository;
  final Future<void> Function() onLogout;

  @override
  State<TermsUpdateDialog> createState() => _TermsUpdateDialogState();
}

class _TermsUpdateDialogState extends State<TermsUpdateDialog> {
  bool _agreed = false;
  bool _busy = false;
  bool _failed = false;

  Future<void> _accept() async {
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      await widget.repository.acceptTerms(widget.version);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _failed = true;
        });
      }
    }
  }

  Future<void> _logout() async {
    setState(() => _busy = true);
    await widget.onLogout();
    if (mounted) Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(l10n.termsUpdateTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.termsUpdateBody),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TermsOfServiceScreen())),
                child: Text(l10n.termsUpdateRead),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _agreed,
                onChanged: _busy ? null : (value) => setState(() => _agreed = value ?? false),
                title: Text(l10n.termsUpdateAgree, style: const TextStyle(fontSize: 13)),
              ),
              if (_failed)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(l10n.termsUpdateFailed, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.red500)),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: _busy ? null : _logout, child: Text(l10n.termsUpdateLogout)),
          SpekoohButton(onPressed: (_agreed && !_busy) ? _accept : null, child: Text(l10n.termsUpdateAccept)),
        ],
      ),
    );
  }
}
