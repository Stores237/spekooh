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
  });

  final int id;
  final String title;
  final String partner;
  final String priceFcfa;
  final int priceFcfaValue;
  final String description;
  final bool deliveryAvailable;
  final int deliveryFeeFcfa;

  /// Backs the Subject/Academic level filter chips on ShopScreen.
  final String subjectTitle;
  final String academicLevel;
}

/// One row of the student's own pamphlet-order history — backs the "Recent
/// shop items" Home card. pamphletTitle mirrors
/// apps.pamphlets.serializers.PamphletOrderSerializer.pamphlet_title (added
/// alongside this feature — the bare "pamphlet" field is just its id).
class PamphletOrder {
  const PamphletOrder({
    required this.id,
    required this.pamphletTitle,
    required this.status,
    required this.amountPaid,
    required this.createdAt,
  });

  final int id;
  final String pamphletTitle;
  final String status;
  final int amountPaid;
  final DateTime createdAt;
}
