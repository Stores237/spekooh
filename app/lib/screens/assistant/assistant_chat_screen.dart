import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../data/api_client.dart';
import '../../data/repositories/assistant_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../../widgets/spekooh_banner.dart';
import '../common/circular_back_button.dart';

/// "Spekooh Assistant" — the real, general-purpose counterpart to
/// PapersScreen's per-paper ChatScreen (apps.ai.views.AssistantChatView,
/// Groq). Not grounded in any one paper's text — a student can ask about
/// any subject, matching what the gold sparkle FAB's own suggested
/// prompts always promised, with nothing real behind them until now.
///
/// Owner-reported (2026-09-12): "the spekooh Assistant don't work at
/// all" — confirmed true: the FAB used to open a fully static bottom
/// sheet with no controller, no tap handlers, no repository call
/// anywhere. This screen (pushed instead of that sheet — a real,
/// growing conversation needs real room, not a cramped modal) is the fix.
/// Ported structure from ChatScreen — same streaming/quota/error handling,
/// only the missing paper context and the suggested-prompts empty state
/// (carried over from the old dead sheet, now real) are different.
class AssistantChatScreen extends StatefulWidget {
  const AssistantChatScreen({super.key, required this.repository, this.onOpenPaywall});

  final AssistantRepository repository;
  final VoidCallback? onOpenPaywall;

  @override
  State<AssistantChatScreen> createState() => _AssistantChatScreenState();
}

class _AssistantChatScreenState extends State<AssistantChatScreen> {
  final _messages = <ChatMessage>[];
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;
  int? _quotaRemaining;
  bool _quotaExceeded = false;

  static List<String> _suggestedPrompts(AppLocalizations l10n) => [
        l10n.aiPromptExplainPhysics,
        l10n.aiPromptMathsQuestions,
        l10n.aiPromptStudyPlan,
      ];

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

  /// Same streaming shape as ChatScreen._send — see that method's own
  /// doc comment for why a mid-stream failure arrives as
  /// [ChatStreamEvent.errorDetail] rather than a thrown exception.
  Future<void> _send([String? presetText]) async {
    final text = (presetText ?? _inputController.text).trim();
    if (text.isEmpty || _sending) return;
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _messages.add(ChatMessage(role: 'user', content: text));
      _inputController.clear();
      _sending = true;
    });
    _scrollToBottom();

    final history = List<ChatMessage>.unmodifiable(_messages);
    final buffer = StringBuffer();
    var assistantBubbleAdded = false;

    try {
      await for (final event in widget.repository.streamMessage(history)) {
        if (event.delta != null) {
          buffer.write(event.delta);
          if (!mounted) return;
          setState(() {
            final bubble = ChatMessage(role: 'assistant', content: buffer.toString());
            if (assistantBubbleAdded) {
              _messages[_messages.length - 1] = bubble;
            } else {
              _messages.add(bubble);
              assistantBubbleAdded = true;
            }
          });
          _scrollToBottom();
        } else if (event.isDone) {
          if (mounted) setState(() => _quotaRemaining = event.quotaRemaining);
        } else if (event.errorDetail != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.chatSendError(event.errorDetail!))));
          }
        }
      }
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
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(12)),
                    alignment: Alignment.center,
                    child: const Icon(LucideIcons.sparkles, color: AppColors.white, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.aiAssistantTitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary)),
                        Text(l10n.aiAssistantSubtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 11, color: AppColors.textSecondary)),
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(l10n.aiAssistantEmptyStateHint, textAlign: TextAlign.center, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, color: AppColors.textSecondary)),
                          const SizedBox(height: AppSpacing.space4),
                          for (final prompt in _suggestedPrompts(l10n)) ...[
                            GestureDetector(
                              onTap: _sending ? null : () => _send(prompt),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(color: AppColors.surfaceCard, border: Border.all(color: AppColors.borderSubtle), borderRadius: BorderRadius.circular(12), boxShadow: AppShadows.card),
                                child: Text(prompt, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, color: AppColors.textPrimary)),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.space2),
                          ],
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPad, vertical: AppSpacing.space3),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) => _AssistantMessageBubble(message: _messages[index]),
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
                          hintText: l10n.aiAssistantInputHint,
                          hintStyle: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, color: AppColors.textTertiary),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    key: const Key('assistantSendButton'),
                    onTap: _quotaExceeded ? null : () => _send(),
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

class _AssistantMessageBubble extends StatelessWidget {
  const _AssistantMessageBubble({required this.message});
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
