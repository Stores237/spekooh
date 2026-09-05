import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/api_client.dart';
import '../../data/repositories/papers_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../../widgets/spekooh_banner.dart';
import '../common/circular_back_button.dart';

/// Lane B — real-time chat about one specific paper (apps.ai.views
/// .PaperChatView, Groq). Only ever pushed for a real, logged-in user on a
/// paper they can already view — see PaperDetailScreen's own entry point,
/// which handles both of those gates before pushing this screen at all.
///
/// Stateless server-side by design (see PapersRepository.sendChatMessage's
/// own doc comment) — this screen is the one place a student's
/// conversation actually lives, for exactly as long as this screen does.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.paperId, required this.paperTitle, required this.repository, this.onOpenPaywall});

  final int paperId;
  final String paperTitle;
  final PapersRepository repository;
  final VoidCallback? onOpenPaywall;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messages = <ChatMessage>[];
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;
  int? _quotaRemaining;
  bool _quotaExceeded = false;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    });
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _sending) return;
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _messages.add(ChatMessage(role: 'user', content: text));
      _inputController.clear();
      _sending = true;
    });
    _scrollToBottom();

    try {
      final reply = await widget.repository.sendChatMessage(widget.paperId, List.unmodifiable(_messages));
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(role: 'assistant', content: reply.content));
        _quotaRemaining = reply.quotaRemaining;
      });
      _scrollToBottom();
    } on ChatQuotaExceededException {
      if (mounted) setState(() => _quotaExceeded = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.chatSendError(apiErrorDetail(e) ?? l10n.authErrorUnknown))));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircularBackButton(onTap: () => Navigator.of(context).pop()),
                  const SizedBox(width: AppSpacing.space2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.chatScreenTitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary)),
                        Text(widget.paperTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  if (_quotaRemaining != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(l10n.chatQuotaRemaining(_quotaRemaining!), style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 10.5, color: AppColors.textTertiary)),
                    ),
                ],
              ),
            ),
            Expanded(
              child: _messages.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPad),
                      child: Center(
                        child: Text(l10n.chatEmptyStateHint, textAlign: TextAlign.center, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, color: AppColors.textSecondary)),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPad, vertical: AppSpacing.space3),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) => _MessageBubble(message: _messages[index]),
                    ),
            ),
            if (_quotaExceeded)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPad),
                child: SpekoohBanner(
                  tone: SpekoohBannerTone.blue,
                  icon: const Icon(LucideIcons.messageCircle),
                  message: l10n.chatQuotaExceededMessage,
                  action: widget.onOpenPaywall == null
                      ? null
                      : GestureDetector(
                          onTap: widget.onOpenPaywall,
                          child: Text(l10n.chatUpgradeButton, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.blue600)),
                        ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.screenPad, AppSpacing.space2, AppSpacing.screenPad, AppSpacing.space3),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(24), boxShadow: AppShadows.card),
                      child: TextField(
                        controller: _inputController,
                        enabled: !_quotaExceeded,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: l10n.chatInputHint,
                          hintStyle: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, color: AppColors.textTertiary),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    key: const Key('chatSendButton'),
                    onTap: _quotaExceeded ? null : _send,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: _quotaExceeded ? AppColors.borderSubtle : AppColors.gold500, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: _sending
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                          : const Icon(LucideIcons.send, size: 18, color: AppColors.white),
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

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.space2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isUser ? AppColors.gold500 : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isUser ? null : AppShadows.card,
        ),
        child: Text(
          message.content,
          style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, height: 1.4, color: isUser ? AppColors.white : AppColors.textPrimary),
        ),
      ),
    );
  }
}
