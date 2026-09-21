import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pdfx/pdfx.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../common/circular_back_button.dart';
import '../../widgets/spekooh_loader.dart';

/// A real in-app document viewer — renders the file inline instead of
/// handing off to the OS's own PDF/photo app, which typically offers its
/// own "Save" affordance. That's the actual enforcement mechanism behind
/// "free to view, paid to download" (owner decision): viewing here never
/// exposes a save-able file the way launching externally would; getting an
/// actual local copy is only possible via the separate, unlock-gated
/// Save-offline action on PaperDetailScreen.
///
/// Opens either a remote file ([fileUrl], fetched over the network) or an
/// already-saved offline copy ([filePath], read from device storage — used by
/// My Downloads, owner request 2026-09-21, so a downloaded paper opens
/// directly and works with no connection). Exactly one of the two.
class ReportViewerScreen extends StatelessWidget {
  const ReportViewerScreen({super.key, required this.title, this.fileUrl, this.filePath})
      : assert((fileUrl != null) != (filePath != null), 'Pass exactly one of fileUrl or filePath');

  final String title;
  final String? fileUrl;
  final String? filePath;

  bool get _isPdf => (filePath ?? Uri.parse(fileUrl!).path).toLowerCase().endsWith('.pdf');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.ink900,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPad, vertical: AppSpacing.space2),
              child: Row(
                children: [
                  CircularBackButton(onTap: () => Navigator.of(context).pop()),
                  const SizedBox(width: AppSpacing.space2),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.white),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _isPdf ? _PdfViewer(fileUrl: fileUrl, filePath: filePath) : _ImageViewer(fileUrl: fileUrl, filePath: filePath)),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.space3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.eye, size: 14, color: AppColors.textOnDarkMuted),
                  const SizedBox(width: 6),
                  Text(l10n.viewOnlyNotice, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 11, color: AppColors.textOnDarkMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PdfViewer extends StatefulWidget {
  const _PdfViewer({this.fileUrl, this.filePath});
  final String? fileUrl;
  final String? filePath;

  @override
  State<_PdfViewer> createState() => _PdfViewerState();
}

class _PdfViewerState extends State<_PdfViewer> {
  late final _controller = PdfControllerPinch(
    document: widget.filePath != null
        ? PdfDocument.openFile(widget.filePath!)
        : http.get(Uri.parse(widget.fileUrl!)).then((r) => PdfDocument.openData(r.bodyBytes)),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PdfViewPinch(
      controller: _controller,
      builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
        options: const DefaultBuilderOptions(),
        documentLoaderBuilder: (context) => const SpekoohLoader(),
        pageLoaderBuilder: (context) => const SpekoohLoader(),
        errorBuilder: (context, error) => Center(
          child: Text(l10n.couldNotOpenFile, style: TextStyle(fontFamily: plusJakartaSansFamily, color: AppColors.white)),
        ),
      ),
    );
  }
}

class _ImageViewer extends StatelessWidget {
  const _ImageViewer({this.fileUrl, this.filePath});
  final String? fileUrl;
  final String? filePath;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PhotoView(
      imageProvider: filePath != null ? FileImage(File(filePath!)) as ImageProvider : NetworkImage(fileUrl!),
      backgroundDecoration: const BoxDecoration(color: AppColors.ink900),
      loadingBuilder: (context, event) => const SpekoohLoader(),
      errorBuilder: (context, error, stackTrace) => Center(
        child: Text(l10n.couldNotOpenFile, style: TextStyle(fontFamily: plusJakartaSansFamily, color: AppColors.white)),
      ),
    );
  }
}
