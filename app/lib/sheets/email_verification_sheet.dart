import 'package:flutter/material.dart';
import '../data/auth_session.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_form_field.dart';
import '../widgets/spekooh_button.dart';

/// Shown right after a successful registration (see AuthSheet._submit) —
/// RegisterView already issued+sent a real code as part of signup itself,
/// this is where the new user actually confirms it. Deliberately skippable
/// (see the "Skip for now" link): registration already granted tokens, and
/// User.email_verified_at doesn't gate access (see that field's docstring
/// on the backend) — this is a nag to verify, not a lockout, since forcing
/// it would strand real users given no real email provider is wired up yet
/// (see TODOS.md).
class EmailVerificationSheet extends StatefulWidget {
  const EmailVerificationSheet({super.key});

  @override
  State<EmailVerificationSheet> createState() => _EmailVerificationSheetState();
}

class _EmailVerificationSheetState extends State<EmailVerificationSheet> {
  bool _isSubmitting = false;
  bool _isResending = false;
  String? _error;
  String? _info;

  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
      _info = null;
    });
    try {
      await AuthSession.instance.confirmEmailVerification(code: _codeController.text.trim());
      if (mounted) Navigator.of(context).pop(true);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = _localizedError(e.code));
    } catch (_) {
      if (mounted) setState(() => _error = AppLocalizations.of(context)!.authErrorUnknown);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _resend() async {
    setState(() {
      _isResending = true;
      _error = null;
      _info = null;
    });
    try {
      await AuthSession.instance.resendEmailVerification();
      if (mounted) setState(() => _info = AppLocalizations.of(context)!.verifyEmailResendSentMessage);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = _localizedError(e.code));
    } catch (_) {
      if (mounted) setState(() => _error = AppLocalizations.of(context)!.authErrorUnknown);
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  String _localizedError(AuthErrorCode code) {
    final l10n = AppLocalizations.of(context)!;
    switch (code) {
      case AuthErrorCode.emailVerificationConfirmFailed:
        return l10n.authErrorEmailVerificationConfirm;
      case AuthErrorCode.emailVerificationResendFailed:
        return l10n.authErrorEmailVerificationResend;
      case AuthErrorCode.loginFailed:
      case AuthErrorCode.loginFailedEmailNotVerified:
      case AuthErrorCode.registerFailedReferral:
      case AuthErrorCode.registerFailedGeneric:
      case AuthErrorCode.registerFailedInvalidEmailDomain:
      case AuthErrorCode.guestFailed:
      case AuthErrorCode.passwordResetRequestFailed:
      case AuthErrorCode.passwordResetConfirmFailed:
        return l10n.authErrorUnknown; // not reachable from this sheet
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      // Grows with the keyboard (see AuthSheet's own comment on this same
      // fix) so it shifts the field above the keyboard instead of letting
      // the keyboard cover it.
      padding: EdgeInsets.fromLTRB(22, 10, 22, 26 + MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: AppShadows.sheet,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.borderSubtle, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              l10n.verifyEmailTitle,
              style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.verifyEmailPrompt,
              style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.space4),
            AuthFieldLabel(l10n.verifyEmailCodeLabel),
            const SizedBox(height: 6),
            AuthTextField(controller: _codeController, hint: l10n.verifyEmailCodeHint, keyboardType: TextInputType.number),
            if (_info != null) ...[
              const SizedBox(height: AppSpacing.space3),
              Text(_info!, style: const TextStyle(color: AppColors.green600, fontSize: 12)),
            ],
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.space3),
              Text(_error!, style: const TextStyle(color: AppColors.red500, fontSize: 12)),
            ],
            const SizedBox(height: AppSpacing.space4),
            SpekoohButton(
              onPressed: _isSubmitting ? null : _confirm,
              child: Text(_isSubmitting ? l10n.authPleaseWait : l10n.verifyEmailConfirmButton),
            ),
            const SizedBox(height: AppSpacing.space3),
            Center(
              child: GestureDetector(
                onTap: _isResending ? null : _resend,
                child: Text(
                  l10n.verifyEmailResendLink,
                  style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.link),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Center(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(false),
                child: Text(
                  l10n.verifyEmailSkipLink,
                  style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
