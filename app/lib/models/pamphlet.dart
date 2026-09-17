class Pamphlet {
  const Pamphlet({
    this.id = 0,
    required this.title,
    required this.partner,
    required this.priceFcfa,
    this.priceFcfaValue = 0,
    this.description = '',
    this.deliveryAvailable = false,
    this.deliveryFeeFcfa = 0,
    this.subjectTitle = '',
    this.academicLevel = '',
    this.coverImageUrl,
    this.partnerLocation = '',
  });

  final int id;
  final String title;
  final String partner;
  final String priceFcfa;
  final int priceFcfaValue;
  final String description;
  final bool deliveryAvailable;
  final int deliveryFeeFcfa;

  /// The real pickup address (owner request, 2026-09-17) -- backs the
  /// "Collect at shop location" map link on PamphletSheet, before the
  /// buyer has even ordered yet.
  final String partnerLocation;

  /// Backs the Subject/Academic level filter chips on ShopScreen.
  final String subjectTitle;
  final String academicLevel;

  /// Null until Integration Ops uploads one (owner request, 2026-09-17) --
  /// FeaturedPamphletCard falls back to the gold subject/level placeholder
  /// rather than fabricating a cover image when this is absent.
  final String? coverImageUrl;
}

/// One row of the student's own pamphlet-order history — backs the "Recent
/// shop items" Home card and the QR Vault pickup card. Field names mirror
/// apps.pamphlets.serializers.PamphletOrderSerializer 1:1 (added alongside
/// this feature — the bare "pamphlet"/"pamphlet.partner" fields are just ids).
class PamphletOrder {
  const PamphletOrder({
    required this.id,
    required this.pamphletTitle,
    required this.status,
    required this.amountPaid,
    required this.createdAt,
    this.qrToken,
    this.qrRedeemUrl,
    this.partnerName = '',
    this.partnerLocation = '',
    this.partnerPhone = '',
    this.partnerWhatsapp = '',
    this.quantity = 1,
    this.deliveryAddress = '',
  });

  final int id;
  final String pamphletTitle;
  final String status;
  final int amountPaid;
  final DateTime createdAt;
  final int quantity;
  final String deliveryAddress;

  /// Null until the order is QR_ISSUED (always true immediately after
  /// ordering per apps.pamphlets.services.place_order's own docstring, but
  /// kept nullable here to match what the API can genuinely return).
  final String? qrToken;

  /// Real, absolute, scannable URL to apps.pamphlets.views.redeem_page —
  /// what QrVaultScreen actually renders as a QR image, not the bare token.
  final String? qrRedeemUrl;
  final String partnerName;
  final String partnerLocation;
  final String partnerPhone;
  final String partnerWhatsapp;
}
