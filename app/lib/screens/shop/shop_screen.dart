import 'package:flutter/material.dart';
import '../../data/repositories/shop_repository.dart';
import '../../data/repository_locator.dart';
import '../../l10n/app_localizations.dart';
import '../../models/pamphlet.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../../widgets/filter_chip_row.dart';
import '../../widgets/search_input.dart';
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
                        Text(l10n.shopTitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 19, color: AppColors.textPrimary)),
                        Text(l10n.shopHeaderSubtitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space4),
              SearchInput(placeholder: l10n.searchPamphlets, controller: _searchController, onChanged: (v) => setState(() => _query = v)),
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
                        if (subjects.isNotEmpty) ...[
                          FilterChipRow(
                            label: l10n.subjectLabel,
                            options: subjects,
                            selected: _subjectFilter,
                            onSelected: (v) => setState(() => _subjectFilter = v),
                          ),
                          const SizedBox(height: AppSpacing.space3),
                        ],
                        if (levels.isNotEmpty) ...[
                          FilterChipRow(
                            label: l10n.academicLevelFilterLabel,
                            options: levels,
                            selected: _levelFilter,
                            onSelected: (v) => setState(() => _levelFilter = v),
                          ),
                          const SizedBox(height: AppSpacing.space4),
                        ],
                        Expanded(
                          child: ListView.separated(
                            itemCount: items.length,
                            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.space3),
                            itemBuilder: (context, i) => _PamphletCard(pamphlet: items[i], onTap: () => widget.onOpenPamphlet?.call(items[i])),
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

class _PamphletCard extends StatelessWidget {
  const _PamphletCard({required this.pamphlet, this.onTap});
  final Pamphlet pamphlet;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(gradient: AppGradients.goldDeep, borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pamphlet.title, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(l10n.pamphletSoldByQr(pamphlet.partner), style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      children: [
                        TextSpan(text: pamphlet.priceFcfa),
                        const TextSpan(text: '  FCFA', style: TextStyle(fontSize: 11, color: AppColors.textTertiary, fontWeight: FontWeight.w600)),
                      ],
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
