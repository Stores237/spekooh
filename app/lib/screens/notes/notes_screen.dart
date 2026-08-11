import 'package:flutter/material.dart';
import '../../data/repositories/notes_repository.dart';
import '../../data/repository_locator.dart';
import '../../models/note.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../../widgets/icon_chip.dart';
import '../../widgets/list_item_row.dart';
import '../../widgets/search_input.dart';
import '../common/circular_back_button.dart';

/// Ported from ui_kits/spekooh-app/NotesScreen.jsx. Pushed as a full-screen
/// overlay (Navigator.push) from wherever "Notes" is tapped — not a bottom
/// tab.
class NotesScreen extends StatefulWidget {
  NotesScreen({super.key, NotesRepository? repository})
      : repository = repository ?? RepositoryLocator.instance.notes;

  final NotesRepository repository;

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  late final Future<List<Note>> _notesFuture = widget.repository.getNotes();
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.space2),
              Row(
                children: [
                  CircularBackButton(onTap: () => Navigator.of(context).pop()),
                  const SizedBox(width: AppSpacing.space3),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notes',
                        style: TextStyle(
                          fontFamily: plusJakartaSansFamily,
                          fontWeight: FontWeight.w800,
                          fontSize: 19,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Topic study notes, contributed alongside papers',
                        style: TextStyle(
                          fontFamily: plusJakartaSansFamily,
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space4),
              SearchInput(
                placeholder: 'Search topics...',
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: AppSpacing.space4),
              Expanded(
                child: FutureBuilder<List<Note>>(
                  future: _notesFuture,
                  builder: (context, snapshot) {
                    final notes = snapshot.data ?? const [];
                    final filtered = notes
                        .where((n) => n.title.toLowerCase().contains(_query.toLowerCase()))
                        .toList();
                    return ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.space3),
                      itemBuilder: (context, i) {
                        final note = filtered[i];
                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: ListItemRow(
                            icon: IconChip(icon: note.icon, tint: note.tint),
                            title: note.title,
                            subtitle: note.subtitle,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
