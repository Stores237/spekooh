/// Ported 1:1 from tokens/spacing.css — 4px base rhythm.
class AppSpacing {
  AppSpacing._();

  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space7 = 32;
  static const double space8 = 40;
  static const double space9 = 48;
  static const double screenPad = 16;

  // Real bug found 2026-09-14 (/design-review, confirmed live at a real
  // 390px mobile viewport): root_shell.dart's Scaffold shows a real
  // floating AIAssistantFab (56px + Flutter's own default margin) once
  // logged in, on every tab — but tab bodies' own scroll views had no
  // bottom padding at all, so a card scrolled to the natural end of the
  // list sat directly underneath it. Measured live: the FAB's real
  // hit-box covered ~60% of the width and 100% of the height of a
  // sponsor card's own "Learn more" button, making it unreachable by
  // tap in that state. Use as bottom padding on any scrollable tab body
  // that can appear while the FAB is visible.
  static const double fabClearance = 96;
}
