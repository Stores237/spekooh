import 'dart:async';

import 'package:flutter/material.dart';
import '../data/auth_session.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_form_field.dart';
import '../widgets/spekooh_button.dart';
import '../screens/legal/privacy_policy_screen.dart';
import 'email_verification_sheet.dart';
import 'password_reset_sheet.dart';

/// Minimal login/register bottom sheet. Wired to Settings' "Log in" button
/// in place of the previous bare local-boolean flip — on success it pops
/// itself and lets the caller (RootShell) flip into the logged-in state.
class AuthSheet extends StatefulWidget {
  const AuthSheet({super.key});

  @override
  State<AuthSheet> createState() => _AuthSheetState();
}

class _AuthSheetState extends State<AuthSheet> {
  bool _isRegisterMode = false;
  bool _isSubmitting = false;
  bool _termsAccepted = false;
  String? _error;

  // Login-time recovery for REQUIRE_EMAIL_VERIFICATION-blocked accounts —
  // see AuthSession.requestEmailVerificationByEmail's docstring for why
  // this needs its own by-email flow instead of reusing EmailVerificationSheet
  // (that one only works from an authenticated session; this one doesn't
  // have one, by definition, since login is exactly what just got refused).
  bool _showLoginRecovery = false;
  bool _isRecoverySubmitting = false;
  String? _recoveryInfo;
  String? _recoveryError;
  final _recoveryCodeController = TextEditingController();

  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _referralCodeController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _referralCodeController.dispose();
    _recoveryCodeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
      _showLoginRecovery = false;
      _recoveryInfo = null;
      _recoveryError = null;
    });
    try {
      if (_isRegisterMode) {
        final needsVerification = await AuthSession.instance.register(
          email: _emailController.text.trim(),
          name: _nameController.text.trim(),
          password: _passwordController.text,
          termsAccepted: _termsAccepted,
          referralCode: _referralCodeController.text.trim(),
        );
        // Already logged in at this point (register() granted tokens) —
        // the verification sheet is a nag, not a gate, so its outcome
        // (confirmed or skipped) doesn't change what happens next here.
        if (needsVerification && mounted) {
          await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const EmailVerificationSheet(),
          );
        }
      } else {
        await AuthSession.instance.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = _localizedAuthError(context, e.code));
      if (e.code == AuthErrorCode.loginFailedEmailNotVerified) {
        // Fire the recovery code immediately — we already know this exact
        // email needs one, no reason to make the user ask for it first.
        unawaited(_startLoginRecovery());
      }
    } catch (_) {
      if (mounted) setState(() => _error = AppLocalizations.of(context)!.authErrorUnknown);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _startLoginRecovery() async {
    if (mounted) setState(() => _showLoginRecovery = true);
    try {
      await AuthSession.instance.requestEmailVerificationByEmail(email: _emailController.text.trim());
      if (mounted) setState(() => _recoveryInfo = AppLocalizations.of(context)!.verifyEmailResendSentMessage);
    } on AuthException catch (e) {
      if (mounted) setState(() => _recoveryError = _localizedAuthError(context, e.code));
    } catch (_) {
      if (mounted) setState(() => _recoveryError = AppLocalizations.of(context)!.authErrorUnknown);
    }
  }

  Future<void> _confirmLoginRecovery() async {
    setState(() {
      _isRecoverySubmitting = true;
      _recoveryError = null;
    });
    try {
      await AuthSession.instance.confirmEmailVerificationByEmail(
        email: _emailController.text.trim(),
        code: _recoveryCodeController.text.trim(),
      );
      if (mounted) {
        setState(() {
          _showLoginRecovery = false;
          _recoveryInfo = null;
          // The password field is already filled in — tapping "Log in"
          // again now succeeds, since email_verified_at just flipped.
          _error = AppLocalizations.of(context)!.verifyEmailLoginRecoveryDoneMessage;
        });
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _recoveryError = _localizedAuthError(context, e.code));
    } catch (_) {
      if (mounted) setState(() => _recoveryError = AppLocalizations.of(context)!.authErrorUnknown);
    } finally {
      if (mounted) setState(() => _isRecoverySubmitting = false);
    }
  }

  String _localizedAuthError(BuildContext context, AuthErrorCode code) {
    final l10n = AppLocalizations.of(context)!;
    switch (code) {
      case AuthErrorCode.loginFailed:
        return l10n.authErrorLogin;
      case AuthErrorCode.loginFailedEmailNotVerified:
        return l10n.authErrorLoginEmailNotVerified;
      case AuthErrorCode.registerFailedReferral:
        return l10n.authErrorRegisterReferral;
      case AuthErrorCode.registerFailedGeneric:
        return l10n.authErrorRegisterGeneric;
      case AuthErrorCode.registerFailedInvalidEmailDomain:
        return l10n.authErrorRegisterInvalidEmailDomain;
      case AuthErrorCode.guestFailed:
        return l10n.authErrorGuest;
      // Reachable here too: _startLoginRecovery/_confirmLoginRecovery call
      // the by-email verification methods when login is blocked.
      case AuthErrorCode.emailVerificationConfirmFailed:
        return l10n.authErrorEmailVerificationConfirm;
      case AuthErrorCode.emailVerificationResendFailed:
        return l10n.authErrorEmailVerificationResend;
      case AuthErrorCode.passwordResetRequestFailed:
      case AuthErrorCode.passwordResetConfirmFailed:
        return l10n.authErrorUnknown; // not reachable from this sheet — see PasswordResetSheet
    }
  }

  Future<void> _openPasswordReset() async {
    final reset = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PasswordResetSheet(),
    );
    if (reset == true && mounted) {
      setState(() {
        _isRegisterMode = false;
        _passwordController.clear();
        _error = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      // Owner-reported (2026-09-02): the keyboard slid up over the email/
      // password fields instead of the sheet shifting to stay above it —
      // showModalBottomSheet doesn't account for the keyboard on its own,
      // the content has to grow its own bottom padding by the keyboard's
      // height (MediaQuery.viewInsets.bottom, 0 when no keyboard is up).
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
              _isRegisterMode ? l10n.authCreateAccountTitle : l10n.authLoginTitle,
              style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.space4),
            if (_isRegisterMode) ...[
              AuthFieldLabel(l10n.authNameLabel),
              const SizedBox(height: 6),
              AuthTextField(controller: _nameController, hint: l10n.authNameHint),
              const SizedBox(height: AppSpacing.space3),
            ],
            AuthFieldLabel(l10n.authEmailLabel),
            const SizedBox(height: 6),
            AuthTextField(controller: _emailController, hint: l10n.authEmailHint, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: AppSpacing.space3),
            AuthFieldLabel(l10n.authPasswordLabel),
            const SizedBox(height: 6),
            AuthTextField(controller: _passwordController, hint: '••••••••', obscureText: true),
            if (!_isRegisterMode) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: _isSubmitting ? null : _openPasswordReset,
                  child: Text(
                    l10n.forgotPasswordLink,
                    style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.link),
                  ),
                ),
              ),
            ],
            if (_isRegisterMode) ...[
              const SizedBox(height: AppSpacing.space3),
              AuthFieldLabel(l10n.authReferralLabel),
              const SizedBox(height: 6),
              AuthTextField(controller: _referralCodeController, hint: l10n.authReferralHint),
              const SizedBox(height: AppSpacing.space3),
              GestureDetector(
                onTap: _isSubmitting ? null : () => setState(() => _termsAccepted = !_termsAccepted),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _termsAccepted,
                      onChanged: _isSubmitting ? null : (value) => setState(() => _termsAccepted = value ?? false),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Text(
                          l10n.authTermsCheckboxLabel,
                          style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Separate from the checkbox's own opaque GestureDetector
              // above so this tap target doesn't fight it for the gesture —
              // previously "Privacy Policy" in the label above was just
              // static text asking users to agree to a document they had
              // no way to actually read.
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 2),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
                  child: Text(
                    l10n.viewPrivacyPolicyLink,
                    style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.gold700, decoration: TextDecoration.underline),
                  ),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.space3),
              Text(_error!, style: const TextStyle(color: AppColors.red500, fontSize: 12)),
            ],
            if (_showLoginRecovery) ...[
              const SizedBox(height: AppSpacing.space3),
              AuthFieldLabel(l10n.verifyEmailCodeLabel),
              const SizedBox(height: 6),
              AuthTextField(controller: _recoveryCodeController, hint: l10n.verifyEmailCodeHint, keyboardType: TextInputType.number),
              if (_recoveryInfo != null) ...[
                const SizedBox(height: AppSpacing.space2),
                Text(_recoveryInfo!, style: const TextStyle(color: AppColors.green600, fontSize: 12)),
              ],
              if (_recoveryError != null) ...[
                const SizedBox(height: AppSpacing.space2),
                Text(_recoveryError!, style: const TextStyle(color: AppColors.red500, fontSize: 12)),
              ],
              const SizedBox(height: AppSpacing.space2),
              SpekoohButton(
                size: SpekoohButtonSize.sm,
                onPressed: _isRecoverySubmitting ? null : _confirmLoginRecovery,
                child: Text(_isRecoverySubmitting ? l10n.authPleaseWait : l10n.verifyEmailConfirmButton),
              ),
              const SizedBox(height: 4),
              Center(
                child: GestureDetector(
                  onTap: _isRecoverySubmitting ? null : _startLoginRecovery,
                  child: Text(
                    l10n.verifyEmailResendLink,
                    style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.link),
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.space4),
            SpekoohButton(
              onPressed: _isSubmitting || (_isRegisterMode && !_termsAccepted) ? null : _submit,
              child: Text(_isSubmitting ? l10n.authPleaseWait : (_isRegisterMode ? l10n.authCreateAccountButton : l10n.authLoginButton)),
            ),
            const SizedBox(height: AppSpacing.space3),
            Center(
              child: GestureDetector(
                onTap: _isSubmitting ? null : () => setState(() => _isRegisterMode = !_isRegisterMode),
                child: Text(
                  _isRegisterMode ? l10n.authSwitchToLogin : l10n.authSwitchToRegister,
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
