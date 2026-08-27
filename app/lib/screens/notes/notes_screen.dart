import 'package:flutter/material.dart';
import '../../data/repositories/notes_repository.dart';
import '../../data/repository_locator.dart';
import '../../l10n/app_localizations.dart';
import '../../models/note.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../../widgets/filter_chip_row.dart';
import '../../widgets/filter_trigger_button.dart';
import '../../widgets/icon_chip.dart';
import '../../widgets/list_item_row.dart';
import '../../widgets/search_input.dart';
import '../../widgets/spekooh_button.dart';
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
  String? _subjectFilter;
  String? _levelFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openFilters(List<String> subjects, List<String> levels) {
    final l10n = AppLocalizations.of(context)!;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.filtersTitle,
                      style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _subjectFilter = null;
                          _levelFilter = null;
                        });
                        setSheetState(() {});
                      },
                      child: Text(
                        l10n.filterClearAll,
                        style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (subjects.isNotEmpty) ...[
                  FilterChipRow(
                    label: l10n.subjectLabel,
                    options: subjects,
                    selected: _subjectFilter,
                    onSelected: (v) {
                      setState(() => _subjectFilter = v);
                      setSheetState(() {});
                    },
                  ),
                  const SizedBox(height: AppSpacing.space4),
                ],
                if (levels.isNotEmpty)
                  FilterChipRow(
                    label: l10n.academicLevelFilterLabel,
                    options: levels,
                    selected: _levelFilter,
                    onSelected: (v) {
                      setState(() => _levelFilter = v);
                      setSheetState(() {});
                    },
                  ),
                const SizedBox(height: AppSpacing.space5),
                SizedBox(
                  width: double.infinity,
                  child: SpekoohButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: Text(l10n.filterDone),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.notesTitle,
                          style: TextStyle(
                            fontFamily: plusJakartaSansFamily,
                            fontWeight: FontWeight.w800,
                            fontSize: 19,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          l10n.notesScreenSubtitle,
                          style: TextStyle(
                            fontFamily: plusJakartaSansFamily,
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space4),
              Expanded(
                child: FutureBuilder<List<Note>>(
                  future: _notesFuture,
                  builder: (context, snapshot) {
                    final notes = snapshot.data ?? const [];
                    // Distinct, real values only — no fabricated "all possible
                    // subjects/levels" list, matching what's actually here.
                    final subjects = notes.map((n) => n.subjectTitle).where((s) => s.isNotEmpty).toSet().toList()
                      ..sort();
                    final levels = notes.map((n) => n.academicLevel).where((s) => s.isNotEmpty).toSet().toList()
                      ..sort();
                    final filtered = notes
                        .where((n) => n.title.toLowerCase().contains(_query.toLowerCase()))
                        .where((n) => _subjectFilter == null || n.subjectTitle == _subjectFilter)
                        .where((n) => _levelFilter == null || n.academicLevel == _levelFilter)
                        .toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: SearchInput(
                                placeholder: l10n.searchTopics,
                                controller: _searchController,
                                onChanged: (v) => setState(() => _query = v),
                              ),
                            ),
                            if (subjects.isNotEmpty || levels.isNotEmpty) ...[
                              const SizedBox(width: AppSpacing.space3),
                              FilterTriggerButton(
                                active: _subjectFilter != null || _levelFilter != null,
                                onTap: () => _openFilters(subjects, levels),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: AppSpacing.space4),
                        Expanded(
                          child: ListView.separated(
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
                          ),
                        ),
                      ],
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
