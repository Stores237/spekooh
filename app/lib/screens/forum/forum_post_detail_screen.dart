import 'package:flutter/material.dart';
import '../../data/repositories/forum_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../models/forum_post.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../../widgets/spekooh_avatar.dart';
import '../../widgets/spekooh_badge.dart';
import '../common/circular_back_button.dart';

/// Post detail + reply thread — reached by tapping a [ForumPost] card.
class ForumPostDetailScreen extends StatefulWidget {
  const ForumPostDetailScreen({super.key, required this.post, required this.repository});
  final ForumPost post;
  final ForumRepository repository;

  @override
  State<ForumPostDetailScreen> createState() => _ForumPostDetailScreenState();
}

class _ForumPostDetailScreenState extends State<ForumPostDetailScreen> {
  late ForumPost _post = widget.post;
  late Future<List<ForumReply>> _repliesFuture = widget.repository.getReplies(_post.id);
  final _replyController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  void _reloadReplies() => setState(() {
        _repliesFuture = widget.repository.getReplies(_post.id);
      });

  Future<void> _toggleUpvote() async {
    final hasUpvoted = await widget.repository.toggleUpvote(_post.id);
    setState(() {
      _post = ForumPost(
        id: _post.id, name: _post.name, time: _post.time, tag: _post.tag, title: _post.title, body: _post.body,
        upvotes: _post.upvotes + (hasUpvoted ? 1 : -1), answers: _post.answers, hasUpvoted: hasUpvoted,
      );
    });
  }

  Future<void> _sendReply() async {
    final body = _replyController.text.trim();
    if (body.isEmpty) return;
    setState(() => _isSending = true);
    try {
      await widget.repository.addReply(_post.id, body);
      _replyController.clear();
      _reloadReplies();
      setState(() => _post = ForumPost(
            id: _post.id, name: _post.name, time: _post.time, tag: _post.tag, title: _post.title, body: _post.body,
            upvotes: _post.upvotes, answers: _post.answers + 1, hasUpvoted: _post.hasUpvoted,
          ));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.surfaceBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPad, vertical: AppSpacing.space2),
              child: Row(
                children: [
                  CircularBackButton(onTap: () => Navigator.of(context).pop()),
                  const SizedBox(width: 12),
                  Text(l10n.questionTitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.textPrimary)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPad),
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.card),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(children: [
                              const SpekoohAvatar(size: 28),
                              const SizedBox(width: 8),
                              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(_post.name, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                Text(_post.time, style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                              ]),
                            ]),
                            SpekoohBadge(text: _post.tag, tone: SpekoohBadgeTone.blue),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(_post.title, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        Text(_post.body, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, color: AppColors.textSecondary)),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: _toggleUpvote,
                          child: Row(children: [
                            Icon(_post.hasUpvoted ? Icons.arrow_upward : Icons.arrow_upward_outlined, size: 16, color: _post.hasUpvoted ? AppColors.gold700 : AppColors.textTertiary),
                            const SizedBox(width: 4),
                            Text('${_post.upvotes}', style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                          ]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  Text(l10n.repliesCount(_post.answers), style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
                  const SizedBox(height: AppSpacing.space2),
                  FutureBuilder<List<ForumReply>>(
                    future: _repliesFuture,
                    builder: (context, snapshot) {
                      final replies = snapshot.data ?? const [];
                      return Column(
                        children: replies
                            .map((r) => Padding(
                                  padding: const EdgeInsets.only(bottom: AppSpacing.space2),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: AppColors.surfaceSunken, borderRadius: BorderRadius.circular(14)),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(r.authorName, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textPrimary)),
                                        const SizedBox(height: 2),
                                        Text(r.body, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                ))
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.space4),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screenPad, 0, AppSpacing.screenPad, AppSpacing.space3),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(color: AppColors.white, border: Border.all(color: AppColors.borderSubtle), borderRadius: BorderRadius.circular(999)),
                      child: TextField(
                        controller: _replyController,
                        decoration: InputDecoration(hintText: l10n.writeReplyHint, border: InputBorder.none, isDense: true),
                        style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _isSending ? null : _sendReply,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(color: AppColors.ink900, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: const Icon(Icons.send, size: 16, color: AppColors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
