import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/qr_vault_biometrics.dart';
import '../data/qr_vault_pin.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// Gates [child] behind a 4-digit PIN the user sets on first visit and
/// enters on every visit after (owner request, 2026-09-16) -- see
/// QrVaultPin's own doc comment for the real security properties this
/// enforces (salted hash, never plaintext, a real attempt-cap lockout).
/// Fingerprint/Face ID unlock (owner request, 2026-09-17) is layered on top,
/// opt-in only -- see QrVaultBiometrics's own doc comment for why a
/// successful biometric match is trusted as equivalent to a correct PIN.
/// A real on-screen number pad (owner reference, 2026-09-17), not a text
/// field + system keyboard -- entering the 4th digit submits immediately.
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

  String _input = '';
  _SetupStep _setupStep = _SetupStep.choose;
  String? _chosenPin;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeAutoTriggerBiometric());
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

  Future<void> _submitSetupStep(AppLocalizations l10n, String value) async {
    if (_setupStep == _SetupStep.choose) {
      setState(() {
        _chosenPin = value;
        _setupStep = _SetupStep.confirm;
        _input = '';
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
        _input = '';
      });
      return;
    }
    setState(() => _busy = true);
    await QrVaultPin.instance.setPin(value);
    if (mounted) await _completeUnlock(l10n);
  }

  Future<void> _submitUnlock(AppLocalizations l10n, String value) async {
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
          _input = '';
          _error = l10n.qrVaultWrongPinAttemptsLeft(remaining);
        });
      case QrVaultPinResult.lockedOut:
        final seconds = await QrVaultPin.instance.lockedOutForSeconds() ?? 0;
        setState(() {
          _busy = false;
          _input = '';
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
      _input = '';
      _setupStep = _SetupStep.choose;
      _chosenPin = null;
      _error = null;
    });
  }

  void _onDigit(AppLocalizations l10n, String digit, VoidCallback onSubmit4th) {
    if (_busy || _input.length >= 4) return;
    setState(() {
      _input += digit;
      _error = null;
    });
    if (_input.length == 4) onSubmit4th();
  }

  void _onBackspace() {
    if (_busy || _input.isEmpty) return;
    setState(() => _input = _input.substring(0, _input.length - 1));
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
    required void Function(AppLocalizations, String) onSubmit,
    VoidCallback? onReset,
  }) {
    return Scaffold(
      backgroundColor: AppColors.surfaceBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPad, vertical: AppSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(color: AppColors.gold200, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: const Icon(LucideIcons.lock, color: AppColors.gold700, size: 26),
                ),
              ),
              const SizedBox(height: AppSpacing.space3),
              Text(title, textAlign: TextAlign.center, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 19, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.space5),
              _PinDots(filled: _input.length),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.space3),
                Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.red500, fontSize: 12)),
              ],
              const SizedBox(height: AppSpacing.space5),
              // Capped so a wide screen (tablet, or a stretched split-screen
              // view) never blows up each key to an absurd size -- the
              // aspect-ratio-based keys below size themselves off the
              // keypad's own width, not the raw device width.
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: _Keypad(
                    busy: _busy,
                    hasInput: _input.isNotEmpty,
                    showFingerprint: _biometricAvailable && _input.isEmpty,
                    forgotLabel: onReset != null ? l10n.qrVaultResetPin : null,
                    onDigit: (digit) => _onDigit(l10n, digit, () => onSubmit(l10n, _input)),
                    onBackspace: _onBackspace,
                    onFingerprint: () => _tryBiometricUnlock(l10n),
                    onForgot: onReset,
                  ),
                ),
              ),
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
      onSubmit: _submitSetupStep,
    );
  }

  Widget _unlockScaffold(AppLocalizations l10n) {
    return _lockScaffold(
      l10n: l10n,
      title: l10n.qrVaultEnterPinTitle,
      subtitle: l10n.qrVaultEnterPinSubtitle,
      onSubmit: _submitUnlock,
      onReset: () => _resetPin(l10n),
    );
  }
}

/// 4 dots, filled solid for every digit typed so far -- never shows the
/// digits themselves.
class _PinDots extends StatelessWidget {
  const _PinDots({required this.filled});
  final int filled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final isFilled = i < filled;
        return Container(
          width: 16,
          height: 16,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? AppColors.gold600 : Colors.transparent,
            border: Border.all(color: AppColors.gold600, width: 1.5),
          ),
        );
      }),
    );
  }
}

/// Real on-screen number pad (owner reference, 2026-09-17) -- 1-9, then a
/// bottom row with Forgot?/0/fingerprint-or-backspace, matching a native
/// phone lock screen rather than a text field + system keyboard.
class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.busy,
    required this.hasInput,
    required this.showFingerprint,
    required this.forgotLabel,
    required this.onDigit,
    required this.onBackspace,
    required this.onFingerprint,
    required this.onForgot,
  });

  final bool busy;
  final bool hasInput;
  final bool showFingerprint;
  final String? forgotLabel;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onFingerprint;
  final VoidCallback? onForgot;

  Widget _key({Widget? child, VoidCallback? onTap}) {
    return Expanded(
      child: AspectRatio(
        aspectRatio: 1.9,
        child: InkWell(
          onTap: busy ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Center(child: child),
        ),
      ),
    );
  }

  Widget _digitKey(String digit) {
    return _key(
      onTap: () => onDigit(digit),
      child: Text(digit, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w600, fontSize: 26, color: AppColors.textPrimary)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(children: [_digitKey('1'), _digitKey('2'), _digitKey('3')]),
        Row(children: [_digitKey('4'), _digitKey('5'), _digitKey('6')]),
        Row(children: [_digitKey('7'), _digitKey('8'), _digitKey('9')]),
        Row(
          children: [
            _key(
              onTap: onForgot,
              child: onForgot != null
                  ? Text(forgotLabel!.toUpperCase(), style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.textSecondary))
                  : null,
            ),
            _digitKey('0'),
            _key(
              onTap: hasInput ? onBackspace : (showFingerprint ? onFingerprint : null),
              child: hasInput
                  ? const Icon(LucideIcons.delete, size: 22, color: AppColors.textSecondary)
                  : (showFingerprint ? const Icon(LucideIcons.fingerprint, size: 24, color: AppColors.gold700) : null),
            ),
          ],
        ),
      ],
    );
  }
}
