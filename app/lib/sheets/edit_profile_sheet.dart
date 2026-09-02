import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/spekooh_user.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_form_field.dart';
import '../widgets/spekooh_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../data/repositories/profile_repository.dart';

/// Real "Edit profile" (owner decision, 2026-08-28, adapting a reference
/// username/email/phone edit sheet) — pre-fills from the already-loaded
/// [user] and saves via ProfileRepository.updateProfile, which was already
/// backed by a real endpoint (PATCH /auth/me/) before this sheet existed.
/// Pops `true` once saved so ProfileScreen knows to refetch; `false`/null
/// on cancel.
class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({super.key, required this.user, required this.repository});

  final SpekoohUser user;
  final ProfileRepository repository;

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late final _nameController = TextEditingController(text: widget.user.name);
  late final _emailController = TextEditingController(text: widget.user.email);
  late final _phoneController = TextEditingController(text: widget.user.phoneNumber);

  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isSaving = true;
      _error = null;
    });
    final newEmail = _emailController.text.trim();
    final emailChanged = newEmail != widget.user.email;
    try {
      await widget.repository.updateProfile(
        name: _nameController.text.trim(),
        email: newEmail,
        phoneNumber: _phoneController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(emailChanged);
    } catch (e) {
      if (mounted) setState(() => _error = l10n.editProfileError('$e'));
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.editProfileTitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.textPrimary)),
                GestureDetector(
                  onTap: _isSaving ? null : () => Navigator.of(context).pop(false),
                  child: const Icon(LucideIcons.x, color: AppColors.textTertiary, size: 22),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space4),
            AuthFieldLabel(l10n.editProfileUsernameLabel),
            const SizedBox(height: 6),
            AuthTextField(controller: _nameController, hint: l10n.editProfileUsernameLabel, enabled: !_isSaving),
            const SizedBox(height: AppSpacing.space3),
            AuthFieldLabel(l10n.authEmailLabel),
            const SizedBox(height: 6),
            AuthTextField(controller: _emailController, hint: l10n.authEmailHint, keyboardType: TextInputType.emailAddress, enabled: !_isSaving),
            const SizedBox(height: AppSpacing.space3),
            AuthFieldLabel(l10n.editProfilePhoneLabel),
            const SizedBox(height: 6),
            AuthTextField(controller: _phoneController, hint: l10n.editProfilePhoneHint, keyboardType: TextInputType.phone, enabled: !_isSaving),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.space3),
              Text(_error!, style: const TextStyle(color: AppColors.red500, fontSize: 12)),
            ],
            const SizedBox(height: AppSpacing.space4),
            SpekoohButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.saveChangesButton),
            ),
            const SizedBox(height: AppSpacing.space3),
            Center(
              child: GestureDetector(
                onTap: _isSaving ? null : () => Navigator.of(context).pop(false),
                child: Text(l10n.cancelButton, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, color: AppColors.textSecondary)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
