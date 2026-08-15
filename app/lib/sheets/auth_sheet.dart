import 'package:flutter/material.dart';
import '../data/auth_session.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../widgets/spekooh_button.dart';

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
  String? _error;

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
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      if (_isRegisterMode) {
        await AuthSession.instance.register(
          email: _emailController.text.trim(),
          name: _nameController.text.trim(),
          password: _passwordController.text,
          referralCode: _referralCodeController.text.trim(),
        );
      } else {
        await AuthSession.instance.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Something went wrong. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              _isRegisterMode ? 'Create your account' : 'Log in to Spekooh',
              style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.space4),
            if (_isRegisterMode) ...[
              _FieldLabel('NAME'),
              const SizedBox(height: 6),
              _TextField(controller: _nameController, hint: 'Your name'),
              const SizedBox(height: AppSpacing.space3),
            ],
            _FieldLabel('EMAIL'),
            const SizedBox(height: 6),
            _TextField(controller: _emailController, hint: 'you@example.com', keyboardType: TextInputType.emailAddress),
            const SizedBox(height: AppSpacing.space3),
            _FieldLabel('PASSWORD'),
            const SizedBox(height: 6),
            _TextField(controller: _passwordController, hint: '••••••••', obscureText: true),
            if (_isRegisterMode) ...[
              const SizedBox(height: AppSpacing.space3),
              _FieldLabel('REFERRAL CODE (OPTIONAL)'),
              const SizedBox(height: 6),
              _TextField(controller: _referralCodeController, hint: 'e.g. A1B2C3D4'),
            ],
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.space3),
              Text(_error!, style: const TextStyle(color: AppColors.red500, fontSize: 12)),
            ],
            const SizedBox(height: AppSpacing.space4),
            SpekoohButton(
              onPressed: _isSubmitting ? null : _submit,
              child: Text(_isSubmitting ? 'Please wait…' : (_isRegisterMode ? 'Create account' : 'Log in')),
            ),
            const SizedBox(height: AppSpacing.space3),
            Center(
              child: GestureDetector(
                onTap: _isSubmitting ? null : () => setState(() => _isRegisterMode = !_isRegisterMode),
                child: Text(
                  _isRegisterMode ? 'Already have an account? Log in' : "New here? Create an account",
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textTertiary, letterSpacing: 0.4),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({required this.controller, required this.hint, this.obscureText = false, this.keyboardType});

  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppColors.white, border: Border.all(color: AppColors.borderSubtle), borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(hintText: hint, border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
        style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 14),
      ),
    );
  }
}
