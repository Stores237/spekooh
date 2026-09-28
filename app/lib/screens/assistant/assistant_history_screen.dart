import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../data/assistant_history_store.dart';
import '../../l10n/app_localizations.dart';
import '../../models/assistant_session.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../common/circular_back_button.dart';

/// The Spekooh Assistant's saved chats, newest first. Tapping one pops this
/// screen with that [AssistantSession] so the chat can pick it up where it
/// left off. Deleting and clearing are confirmed first, and act on this phone
/// only (that is the only place a chat is kept).
class AssistantHistoryScreen extends StatefulWidget {
  const AssistantHistoryScreen({super.key, required this.store});

  final AssistantHistoryStore store;

  @override
  State<AssistantHistoryScreen> createState() => _AssistantHistoryScreenState();
}

class _AssistantHistoryScreenState extends State<AssistantHistoryScreen> {
  late Future<List<AssistantSession>> _future = widget.store.list();

  void _reload() {
    setState(() {
      _future = widget.store.list();
    });
  }

  Future<bool> _confirm({required String title, required String body}) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.assistantHistoryCancel)),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(l10n.assistantHistoryConfirmDelete)),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _delete(AssistantSession session) async {
    final l10n = AppLocalizations.of(context)!;
    if (!await _confirm(title: l10n.assistantHistoryDeleteTitle, body: l10n.assistantHistoryDeleteBody)) return;
    await widget.store.delete(session.id);
    if (mounted) _reload();
  }

  Future<void> _clearAll() async {
    final l10n = AppLocalizations.of(context)!;
    if (!await _confirm(title: l10n.assistantHistoryClearTitle, body: l10n.assistantHistoryClearBody)) return;
    await widget.store.clear();
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.surfaceBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPad),
          child: FutureBuilder<List<AssistantSession>>(
            future: _future,
            builder: (context, snapshot) {
              final sessions = snapshot.data ?? const <AssistantSession>[];
              final loaded = snapshot.connectionState == ConnectionState.done;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.space2),
                  Row(
                    children: [
                      CircularBackButton(onTap: () => Navigator.of(context).pop()),
                      const SizedBox(width: AppSpacing.space3),
                      Expanded(
                        child: Text(
                          l10n.assistantHistoryTitle,
                          style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.textPrimary),
                        ),
                      ),
                      if (sessions.isNotEmpty)
                        TextButton(
                          onPressed: _clearAll,
                          child: Text(l10n.assistantHistoryClearAll, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.red500)),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  Expanded(
                    child: !loaded
                        ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                        : sessions.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
                                  child: Text(
                                    l10n.assistantHistoryEmpty,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 14, color: AppColors.textSecondary),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                itemCount: sessions.length,
                                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.space3),
                                itemBuilder: (context, index) => _row(context, l10n, sessions[index]),
                              ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, AppLocalizations l10n, AssistantSession session) {
    final date = MaterialLocalizations.of(context).formatShortDate(session.updatedAt);
    return InkWell(
      onTap: () => Navigator.of(context).pop(session),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
        decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.title.isEmpty ? l10n.assistantNewChat : session.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${l10n.assistantHistoryMessageCount(session.messages.length)} · $date',
                    style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: l10n.assistantHistoryConfirmDelete,
              onPressed: () => _delete(session),
              icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}
