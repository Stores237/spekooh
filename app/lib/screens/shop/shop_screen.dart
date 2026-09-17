import 'package:flutter/material.dart';
import '../../data/repositories/shop_repository.dart';
import '../../data/repository_locator.dart';
import '../../l10n/app_localizations.dart';
import '../../models/pamphlet.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../../widgets/filter_chip_row.dart';
import '../../widgets/filter_trigger_button.dart';
import '../../widgets/pamphlet_cover_image.dart';
import '../../widgets/search_input.dart';
import '../../widgets/spekooh_button.dart';
import '../common/circular_back_button.dart';

/// Ported from ui_kits/spekooh-app/ShopScreen.jsx. Pushed as a full-screen
/// overlay; tapping a pamphlet opens PamphletSheet (wired in a later stage).
class ShopScreen extends StatefulWidget {
  ShopScreen({super.key, ShopRepository? repository, this.onOpenPamphlet})
      : repository = repository ?? RepositoryLocator.instance.shop;

  final ShopRepository repository;
  final ValueChanged<Pamphlet>? onOpenPamphlet;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late final Future<List<Pamphlet>> _pamphletsFuture = widget.repository.getPamphlets();
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
                        Text(l10n.pamphletShopTitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 19, color: AppColors.textPrimary)),
                        Text(l10n.shopHeaderSubtitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space4),
              Expanded(
                child: FutureBuilder<List<Pamphlet>>(
                  future: _pamphletsFuture,
                  builder: (context, snapshot) {
                    final pamphlets = snapshot.data ?? const <Pamphlet>[];
                    final subjects = pamphlets.map((p) => p.subjectTitle).where((s) => s.isNotEmpty).toSet().toList()
                      ..sort();
                    final levels = pamphlets.map((p) => p.academicLevel).where((s) => s.isNotEmpty).toSet().toList()
                      ..sort();
                    final items = pamphlets
                        .where((p) => p.title.toLowerCase().contains(_query.toLowerCase()))
                        .where((p) => _subjectFilter == null || p.subjectTitle == _subjectFilter)
                        .where((p) => _levelFilter == null || p.academicLevel == _levelFilter)
                        .toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: SearchInput(
                                placeholder: l10n.searchPamphlets,
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
                          child: GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: AppSpacing.space3,
                              mainAxisSpacing: AppSpacing.space3,
                              childAspectRatio: 0.62,
                            ),
                            itemCount: items.length,
                            itemBuilder: (context, i) => _PamphletGridTile(pamphlet: items[i], onTap: () => widget.onOpenPamphlet?.call(items[i])),
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

/// Owner reference, 2026-09-17 (Kawlo's "Pamphlet Shop" grid): cover image
/// on top, truncated title + price below, an inline Buy button -- replacing
/// the previous single-column list card. Cover handling is shared with
/// FeaturedPamphletCard via PamphletCoverImage.
class _PamphletGridTile extends StatelessWidget {
  const _PamphletGridTile({required this.pamphlet, this.onTap});
  final Pamphlet pamphlet;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) => PamphletCoverImage(
                pamphlet: pamphlet,
                width: constraints.maxWidth,
                height: constraints.maxWidth * 1.25,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pamphlet.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textPrimary),
                            children: [
                              TextSpan(text: pamphlet.priceFcfa),
                              const TextSpan(text: ' FCFA', style: TextStyle(fontSize: 10, color: AppColors.textTertiary, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                      SpekoohButton(size: SpekoohButtonSize.sm, onPressed: onTap, child: Text(l10n.buy)),
                    ],
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
