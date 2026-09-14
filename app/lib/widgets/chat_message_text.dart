import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../theme/app_theme.dart';

/// Renders a chat message's content as real Markdown — Groq/Gemini both
/// format replies with **bold**, numbered/bulleted lists, etc., which a
/// plain [Text] widget showed as literal asterisks/dashes instead of
/// rendering (real bug found live, 2026-09-14, screenshot showed a French
/// reply as raw "**Quelles matières...**" text). Shared by both AI chat
/// surfaces (papers/chat_screen.dart's per-paper chat and
/// assistant/assistant_chat_screen.dart's general assistant) since they
/// render messages identically otherwise.
class ChatMessageText extends StatelessWidget {
  const ChatMessageText({super.key, required this.content, required this.color});

  final String content;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final baseStyle = TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, height: 1.4, color: color);
    return MarkdownBody(
      data: content,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: baseStyle,
        strong: baseStyle.copyWith(fontWeight: FontWeight.w800),
        em: baseStyle.copyWith(fontStyle: FontStyle.italic),
        listBullet: baseStyle,
        h1: baseStyle.copyWith(fontSize: 17, fontWeight: FontWeight.w800),
        h2: baseStyle.copyWith(fontSize: 15, fontWeight: FontWeight.w800),
        h3: baseStyle.copyWith(fontSize: 14, fontWeight: FontWeight.w800),
        code: baseStyle.copyWith(fontFamily: 'monospace', backgroundColor: color.withValues(alpha: 0.08)),
        blockquote: baseStyle.copyWith(color: color.withValues(alpha: 0.75)),
        // Bubbles size themselves to content (BoxConstraints maxWidth in
        // the calling widget) — no extra vertical margin needed between
        // Markdown blocks the way a full-page document would want.
        blockSpacing: 6,
        listIndent: 18,
      ),
    );
  }
}
