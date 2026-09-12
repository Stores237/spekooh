import 'package:flutter/material.dart';
import '../data/repository_locator.dart';
import '../screens/assistant/assistant_chat_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_gradients.dart';
import '../theme/app_shadows.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A floating action button, bottom-right above the bottom nav, shown
/// only when logged in. Pushes the real [AssistantChatScreen] — a
/// full-screen, growing conversation needs real room, not a modal sheet
/// (which is what this used to open, entirely static: see git history/
/// TODOS.md #15 for the "the spekooh Assistant don't work at all" bug
/// this replaces — no controller, no tap handlers, nothing wired to any
/// repository at all).
class AIAssistantFab extends StatelessWidget {
  const AIAssistantFab({super.key, this.onOpenPaywall});

  /// Threaded through to [AssistantChatScreen] for its own quota-exceeded
  /// upgrade prompt — same pattern as PaperDetailScreen's ChatScreen.
  final VoidCallback? onOpenPaywall;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AssistantChatScreen(repository: RepositoryLocator.instance.assistant, onOpenPaywall: onOpenPaywall),
        ),
      ),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(gradient: AppGradients.primary, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.button),
        alignment: Alignment.center,
        child: const Icon(LucideIcons.sparkles, color: AppColors.white, size: 22),
      ),
    );
  }
}
