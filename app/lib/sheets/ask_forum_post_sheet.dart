import 'package:flutter/material.dart';
import '../data/repositories/forum_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../widgets/spekooh_button.dart';

/// The Forum tab's "+ Ask" flow — a minimal tag/title/body form, posting
/// via [ForumRepository.createPost]. Pops with the created post on success.
class AskForumPostSheet extends StatefulWidget {
  const AskForumPostSheet({super.key, required this.repository});
  final ForumRepository repository;

  @override
  State<AskForumPostSheet> createState() => _AskForumPostSheetState();
}

class _AskForumPostSheetState extends State<AskForumPostSheet> {
  final _tagController = TextEditingController();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _tagController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty || _bodyController.text.trim().isEmpty) {
      setState(() => _error = 'Title and question are required.');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final post = await widget.repository.createPost(
        tag: _tagController.text.trim().isEmpty ? 'General' : _tagController.text.trim(),
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(post);
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
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.borderSubtle, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: AppSpacing.space4),
            Text('Ask the forum', style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.textPrimary)),
            const SizedBox(height: AppSpacing.space4),
            _Field(controller: _tagController, hint: 'Subject (e.g. Physics)'),
            const SizedBox(height: AppSpacing.space3),
            _Field(controller: _titleController, hint: 'Question title'),
            const SizedBox(height: AppSpacing.space3),
            _Field(controller: _bodyController, hint: 'Explain what you need help with…', maxLines: 4),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.space3),
              Text(_error!, style: const TextStyle(color: AppColors.red500, fontSize: 12)),
            ],
            const SizedBox(height: AppSpacing.space4),
            SpekoohButton(onPressed: _isSubmitting ? null : _submit, child: Text(_isSubmitting ? 'Posting…' : 'Post question')),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.hint, this.maxLines = 1});
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppColors.white, border: Border.all(color: AppColors.borderSubtle), borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(hintText: hint, border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
        style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 14),
      ),
    );
  }
}
