import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('web/index.html has pdf.js installed for pdfx — required for the in-app document viewer', () {
    // Regression: pdfx (used by ReportViewerScreen's PDF viewer) has no
    // "web" entry in its own pubspec platforms list — its web support only
    // works if `dart run pdfx:install_web` has injected pdf.js into
    // web/index.html. Without it, pdfx's web renderer throws
    // "pdf.js not added in web/index.html" on every single PDF, which
    // ReportViewerScreen's generic errorBuilder swallows into
    // l10n.couldNotOpenFile ("Impossible d'ouvrir le fichier.") — so every
    // PDF report/paper silently failed to open in the in-app viewer.
    //
    // web/index.html is a checked-in source file, not build output — a
    // `flutter create .` re-scaffold or a hand-revert can silently drop
    // this again, so guard it here rather than relying on someone noticing
    // the app is broken.
    final indexHtml = File('web/index.html').readAsStringSync();
    expect(indexHtml, contains('pdfjsLib'), reason: 'run `dart run pdfx:install_web` to fix');
  });
}
