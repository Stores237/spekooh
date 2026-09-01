import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The one branded loading treatment for "this page/section's data hasn't
/// arrived yet" (a screen's initial `FutureBuilder`, a document/page
/// loading inside the report viewer). Owner-requested (2026-09-01): screens
/// were each using Flutter's own bare default gray spinner, which reads as
/// unfinished/unstyled rather than a deliberate part of the app. This is
/// gold to match the splash screen and the rest of the brand palette —
/// nothing else changes about how/when a screen decides to show it.
///
/// Not for small inline button-press spinners (submit/unlock/subscribe) —
/// those are already correctly scoped, sized, and often colored to contrast
/// against a filled button; this widget is specifically the page/section-
/// level "waiting for real data" state.
class SpekoohLoader extends StatelessWidget {
  const SpekoohLoader({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: const CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.gold500),
      ),
    );
  }
}
