import 'dart:io';
import 'dart:typed_data';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/repositories/papers_repository.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../widgets/spekooh_button.dart';

/// Owner-requested (2026-09-11): a submitted paper/report is often more than
/// one physical page — this scans several pages in sequence via the "+"
/// tile below and combines them into a single multi-page PDF, matching the
/// one-file-per-submission model everywhere else on the Submit screen. Each
/// page scan still auto-crops via CunningDocumentScanner (ML Kit/VisionKit),
/// same as the single-page flow this replaces; combining pages is a pure
/// client-side PDF assembly step (package:pdf) — no new backend concept,
/// the result is just one more file for the existing upload path.
///
/// Returns null if the very first scan is cancelled (matches this screen's
/// existing "cancelled scan is a no-op" precedent everywhere else) or if
/// the sheet is dismissed with zero pages collected.
Future<SubmissionFile?> showScanPagesSheet(BuildContext context) async {
  final first = await _scanOnePage();
  if (first == null || !context.mounted) return null;

  final pages = await showModalBottomSheet<List<Uint8List>>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    builder: (context) => ScanPagesSheet(initialPages: [first]),
  );
  if (pages == null || pages.isEmpty) return null;

  final pdfBytes = await _combineToPdf(pages);
  return SubmissionFile(bytes: pdfBytes, fileName: 'scan_${DateTime.now().millisecondsSinceEpoch}.pdf', mimeType: 'application/pdf');
}

/// `null` covers both a user-cancelled scan and a real scanner error
/// (CunningDocumentScannerException) — same reasoning as the single-page
/// flow this replaces: a failed/cancelled scan is just retryable, not a
/// distinct error state.
Future<Uint8List?> _scanOnePage() async {
  List<String>? paths;
  try {
    paths = await CunningDocumentScanner.getPictures(noOfPages: 1);
  } catch (_) {
    return null;
  }
  final path = paths?.firstOrNull;
  if (path == null) return null;
  return File(path).readAsBytes();
}

Future<Uint8List> _combineToPdf(List<Uint8List> pages) async {
  final doc = pw.Document();
  for (final bytes in pages) {
    final image = pw.MemoryImage(bytes);
    doc.addPage(pw.Page(build: (context) => pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain))));
  }
  return doc.save();
}

class ScanPagesSheet extends StatefulWidget {
  const ScanPagesSheet({super.key, required this.initialPages});
  final List<Uint8List> initialPages;

  @override
  State<ScanPagesSheet> createState() => ScanPagesSheetState();
}

class ScanPagesSheetState extends State<ScanPagesSheet> {
  late final List<Uint8List> _pages = List.of(widget.initialPages);
  bool _scanning = false;

  Future<void> _addPage() async {
    setState(() => _scanning = true);
    final page = await _scanOnePage();
    if (!mounted) return;
    setState(() {
      _scanning = false;
      if (page != null) _pages.add(page);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(key: const Key('scanPagesCloseButton'), onTap: () => Navigator.of(context).pop(), child: const Icon(LucideIcons.x)),
                  const SizedBox(width: 12),
                  Text(l10n.scanPagesTitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.textPrimary)),
                ],
              ),
              const SizedBox(height: 6),
              Text(l10n.scanPagesHint, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.space4),
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (var i = 0; i < _pages.length; i++) _pageThumbnail(i),
                      _addPageTile(l10n),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              SizedBox(
                width: double.infinity,
                child: SpekoohButton(
                  onPressed: _pages.isEmpty ? null : () => Navigator.of(context).pop(_pages),
                  child: Text(_pages.length == 1 ? l10n.scanUsePageSingular : l10n.scanUsePagesPlural(_pages.length)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pageThumbnail(int index) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 84,
          height: 112,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderSubtle),
            image: DecorationImage(image: MemoryImage(_pages[index]), fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            key: Key('scanRemovePageButton_$index'),
            onTap: () => setState(() => _pages.removeAt(index)),
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.ink900),
              alignment: Alignment.center,
              child: const Icon(LucideIcons.x, size: 12, color: AppColors.white),
            ),
          ),
        ),
        Positioned(
          bottom: 4,
          left: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: AppColors.ink900.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(999)),
            child: Text('${index + 1}', style: const TextStyle(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _addPageTile(AppLocalizations l10n) {
    return GestureDetector(
      key: const Key('scanAddPageButton'),
      onTap: _scanning ? null : _addPage,
      child: Container(
        width: 84,
        height: 112,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderSubtle),
          color: AppColors.surfaceSunken,
        ),
        alignment: Alignment.center,
        child: _scanning
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.plus, color: AppColors.textSecondary),
                  const SizedBox(height: 4),
                  Text(l10n.scanAddPage, textAlign: TextAlign.center, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 10, color: AppColors.textSecondary)),
                ],
              ),
      ),
    );
  }
}
