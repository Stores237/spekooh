import 'package:flutter/material.dart';
import '../data/auth_session.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_form_field.dart';
import '../widgets/spekooh_button.dart';

/// Two-step "forgot password" flow: request a code by email, then confirm
/// it alongside a new password. Reached from AuthSheet's login mode.
/// Pops `true` once the password is actually reset — the caller (AuthSheet)
/// reacts by dropping back to its own login form so the user can log in
/// with the new password; this sheet never logs anyone in itself.
class PasswordResetSheet extends StatefulWidget {
  const PasswordResetSheet({super.key});

  @override
  State<PasswordResetSheet> createState() => _PasswordResetSheetState();
}

class _PasswordResetSheetState extends State<PasswordResetSheet> {
  bool _codeSent = false;
  bool _isSubmitting = false;
  String? _error;

  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await AuthSession.instance.requestPasswordReset(email: _emailController.text.trim());
      if (mounted) setState(() => _codeSent = true);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = _localizedError(e.code));
    } catch (_) {
      if (mounted) setState(() => _error = AppLocalizations.of(context)!.authErrorUnknown);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _confirmReset() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await AuthSession.instance.confirmPasswordReset(
        email: _emailController.text.trim(),
        code: _codeController.text.trim(),
        newPassword: _newPasswordController.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = _localizedError(e.code));
    } catch (_) {
      if (mounted) setState(() => _error = AppLocalizations.of(context)!.authErrorUnknown);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _localizedError(AuthErrorCode code) {
    final l10n = AppLocalizations.of(context)!;
    switch (code) {
      case AuthErrorCode.passwordResetRequestFailed:
        return l10n.authErrorPasswordResetRequest;
      case AuthErrorCode.passwordResetConfirmFailed:
        return l10n.authErrorPasswordResetConfirm;
      case AuthErrorCode.loginFailed:
      case AuthErrorCode.loginFailedEmailNotVerified:
      case AuthErrorCode.registerFailedReferral:
      case AuthErrorCode.registerFailedGeneric:
      case AuthErrorCode.registerFailedInvalidEmailDomain:
      case AuthErrorCode.guestFailed:
      case AuthErrorCode.emailVerificationConfirmFailed:
      case AuthErrorCode.emailVerificationResendFailed:
        return l10n.authErrorUnknown; // not reachable from this sheet
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 26),
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
              l10n.resetPasswordTitle,
              style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              _codeSent ? l10n.resetPasswordCodeSentMessage : l10n.resetPasswordEmailPrompt,
              style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.space4),
            AuthFieldLabel(l10n.authEmailLabel),
            const SizedBox(height: 6),
            AuthTextField(
              controller: _emailController,
              hint: l10n.authEmailHint,
              keyboardType: TextInputType.emailAddress,
              enabled: !_codeSent,
            ),
            if (_codeSent) ...[
              const SizedBox(height: AppSpacing.space3),
              AuthFieldLabel(l10n.resetPasswordCodeLabel),
              const SizedBox(height: 6),
              AuthTextField(controller: _codeController, hint: l10n.resetPasswordCodeHint, keyboardType: TextInputType.number),
              const SizedBox(height: AppSpacing.space3),
              AuthFieldLabel(l10n.resetPasswordNewPasswordLabel),
              const SizedBox(height: 6),
              AuthTextField(controller: _newPasswordController, hint: '••••••••', obscureText: true),
            ],
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.space3),
              Text(_error!, style: const TextStyle(color: AppColors.red500, fontSize: 12)),
            ],
            const SizedBox(height: AppSpacing.space4),
            SpekoohButton(
              onPressed: _isSubmitting ? null : (_codeSent ? _confirmReset : _sendCode),
              child: Text(
                _isSubmitting
                    ? l10n.authPleaseWait
                    : (_codeSent ? l10n.resetPasswordConfirmButton : l10n.resetPasswordSendCodeButton),
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            Center(
              child: GestureDetector(
                onTap: _isSubmitting ? null : () => Navigator.of(context).pop(false),
                child: Text(
                  l10n.resetPasswordBackToLogin,
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
