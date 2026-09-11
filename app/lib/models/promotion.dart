/// A sponsor/promotion slot for Home (owner request, 2026-09-11) —
/// scaffolded ahead of any real sponsor deal existing yet. Only ever
/// non-empty once a real Promotion row is marked active in Django admin;
/// LoggedInHomeScreen hides its section entirely otherwise, same "no
/// section rather than a fake one" pattern used elsewhere in this app.
class Promotion {
  const Promotion({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.sponsorName = '',
    this.iconName = '',
    this.logoUrl,
    this.ctaLabel = '',
    this.ctaUrl = '',
  });

  final int id;
  final String title;
  final String subtitle;
  final String sponsorName;
  final String iconName;

  /// Null means no real sponsor logo uploaded — the card falls back to
  /// [iconName] (or a generic icon) rather than a fabricated image.
  final String? logoUrl;
  final String ctaLabel;
  final String ctaUrl;
}
