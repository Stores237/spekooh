import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/qr_vault_biometrics.dart';
import '../data/qr_vault_pin.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import 'auth_form_field.dart';
import 'spekooh_button.dart';

/// Gates [child] behind a 4-digit PIN the user sets on first visit and
/// enters on every visit after (owner request, 2026-09-16) -- see
/// QrVaultPin's own doc comment for the real security properties this
/// enforces (salted hash, never plaintext, a real attempt-cap lockout).
/// Fingerprint/Face ID unlock (owner request, 2026-09-17) is layered on top,
/// opt-in only -- see QrVaultBiometrics's own doc comment for why a
/// successful biometric match is trusted as equivalent to a correct PIN.
class QrVaultLockGate extends StatefulWidget {
  const QrVaultLockGate({super.key, required this.child});
  final Widget child;

  @override
  State<QrVaultLockGate> createState() => _QrVaultLockGateState();
}

enum _SetupStep { choose, confirm }

class _QrVaultLockGateState extends State<QrVaultLockGate> {
  Future<bool> _hasPinFuture = QrVaultPin.instance.hasPin();
  bool _unlocked = false;
  bool _biometricAvailable = false;

  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  _SetupStep _setupStep = _SetupStep.choose;
  String? _chosenPin;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutoTriggerBiometric());
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _maybeAutoTriggerBiometric() async {
    final hasPin = await QrVaultPin.instance.hasPin();
    if (!hasPin) return;
    final enabled = await QrVaultBiometrics.instance.isEnabled();
    if (!enabled) return;
    final supported = await QrVaultBiometrics.instance.isDeviceSupported();
    if (!supported || !mounted) return;
    setState(() => _biometricAvailable = true);
    final l10n = AppLocalizations.of(context)!;
    await _tryBiometricUnlock(l10n);
  }

  Future<void> _tryBiometricUnlock(AppLocalizations l10n) async {
    if (_busy) return;
    setState(() => _busy = true);
    final success = await QrVaultBiometrics.instance.authenticate(l10n.qrVaultBiometricReason);
    if (!mounted) return;
    if (success) {
      setState(() => _unlocked = true);
    } else {
      setState(() => _busy = false);
    }
  }

  /// Reveals the vault immediately (both PIN-setup and PIN-entry call this
  /// on success), then -- once, ever, per device -- offers fingerprint/Face
  /// ID as a faster way in next time.
  Future<void> _completeUnlock(AppLocalizations l10n) async {
    if (mounted) setState(() => _unlocked = true);
    final supported = await QrVaultBiometrics.instance.isDeviceSupported();
    if (!supported) return;
    final alreadyPrompted = await QrVaultBiometrics.instance.hasBeenPrompted();
    if (alreadyPrompted || !mounted) return;
    await _offerBiometricEnrollment(l10n);
  }

  Future<void> _offerBiometricEnrollment(AppLocalizations l10n) async {
    final enable = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.qrVaultEnableBiometricTitle),
        content: Text(l10n.qrVaultEnableBiometricBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.qrVaultEnableBiometricNotNow)),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(l10n.qrVaultEnableBiometricEnable)),
        ],
      ),
    );
    await QrVaultBiometrics.instance.markPrompted();
    if (enable != true) return;
    // Confirm the enrollment with a real prompt right away, rather than
    // flipping the setting on trust alone -- if this fails (cancelled,
    // hardware error), never silently enable something that wasn't proven
    // to work.
    final confirmed = await QrVaultBiometrics.instance.authenticate(l10n.qrVaultBiometricReason);
    if (confirmed) await QrVaultBiometrics.instance.setEnabled(true);
  }

  Future<void> _submitSetupStep(AppLocalizations l10n) async {
    final value = _pinController.text.trim();
    if (value.length != 4 || int.tryParse(value) == null) {
      setState(() => _error = l10n.qrVaultPinMustBe4Digits);
      return;
    }
    if (_setupStep == _SetupStep.choose) {
      setState(() {
        _chosenPin = value;
        _setupStep = _SetupStep.confirm;
        _pinController.clear();
        _error = null;
      });
      return;
    }
    // Confirm step.
    if (value != _chosenPin) {
      setState(() {
        _error = l10n.qrVaultPinsDontMatch;
        _setupStep = _SetupStep.choose;
        _chosenPin = null;
        _pinController.clear();
      });
      return;
    }
    setState(() => _busy = true);
    await QrVaultPin.instance.setPin(value);
    if (mounted) await _completeUnlock(l10n);
  }

  Future<void> _submitUnlock(AppLocalizations l10n) async {
    final value = _pinController.text.trim();
    if (value.length != 4) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await QrVaultPin.instance.verifyPin(value);
    if (!mounted) return;
    switch (result) {
      case QrVaultPinResult.success:
        await _completeUnlock(l10n);
      case QrVaultPinResult.wrongPin:
        final remaining = await QrVaultPin.instance.attemptsRemaining();
        setState(() {
          _busy = false;
          _pinController.clear();
          _error = l10n.qrVaultWrongPinAttemptsLeft(remaining);
        });
      case QrVaultPinResult.lockedOut:
        final seconds = await QrVaultPin.instance.lockedOutForSeconds() ?? 0;
        setState(() {
          _busy = false;
          _pinController.clear();
          _error = l10n.qrVaultLockedOut((seconds / 60).ceil());
        });
    }
  }

  Future<void> _resetPin(AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.qrVaultResetPinConfirmTitle),
        content: Text(l10n.qrVaultResetPinConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.doneLabel)),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(l10n.qrVaultResetPinConfirmAction)),
        ],
      ),
    );
    if (confirmed != true) return;
    await QrVaultPin.instance.resetPin();
    if (!mounted) return;
    setState(() {
      _hasPinFuture = QrVaultPin.instance.hasPin();
      _pinController.clear();
      _confirmController.clear();
      _setupStep = _SetupStep.choose;
      _chosenPin = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_unlocked) return widget.child;

    return FutureBuilder<bool>(
      future: _hasPinFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return snapshot.data! ? _unlockScaffold(l10n) : _setupScaffold(l10n);
      },
    );
  }

  Widget _lockScaffold({
    required AppLocalizations l10n,
    required String title,
    required String subtitle,
    required VoidCallback onSubmit,
    VoidCallback? onReset,
  }) {
    return Scaffold(
      backgroundColor: AppColors.surfaceBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPad),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(color: AppColors.gold200, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: const Icon(LucideIcons.lock, color: AppColors.gold700, size: 30),
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(title, textAlign: TextAlign.center, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 19, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.space5),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.card),
                child: AuthTextField(
                  controller: _pinController,
                  hint: l10n.qrVaultPinHint,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  enabled: !_busy,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 4,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.space2),
                Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.red500, fontSize: 12)),
              ],
              const SizedBox(height: AppSpacing.space4),
              SpekoohButton(onPressed: _busy ? null : onSubmit, child: Text(_busy ? l10n.processingLabel : l10n.qrVaultContinue)),
              if (_biometricAvailable) ...[
                const SizedBox(height: AppSpacing.space2),
                TextButton.icon(
                  onPressed: _busy ? null : () => _tryBiometricUnlock(l10n),
                  icon: const Icon(LucideIcons.fingerprint, size: 16, color: AppColors.gold700),
                  label: Text(l10n.qrVaultUseFingerprint, style: TextStyle(fontFamily: plusJakartaSansFamily, color: AppColors.gold700)),
                ),
              ],
              if (onReset != null) ...[
                const SizedBox(height: AppSpacing.space2),
                TextButton(
                  onPressed: _busy ? null : () => onReset(),
                  child: Text(l10n.qrVaultResetPin, style: TextStyle(fontFamily: plusJakartaSansFamily, color: AppColors.red500)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _setupScaffold(AppLocalizations l10n) {
    return _lockScaffold(
      l10n: l10n,
      title: l10n.qrVaultSetPinTitle,
      subtitle: _setupStep == _SetupStep.choose ? l10n.qrVaultSetPinSubtitle : l10n.qrVaultConfirmPinSubtitle,
      onSubmit: () => _submitSetupStep(l10n),
    );
  }

  Widget _unlockScaffold(AppLocalizations l10n) {
    return _lockScaffold(
      l10n: l10n,
      title: l10n.qrVaultEnterPinTitle,
      subtitle: l10n.qrVaultEnterPinSubtitle,
      onSubmit: () => _submitUnlock(l10n),
      onReset: () => _resetPin(l10n),
    );
  }
}
