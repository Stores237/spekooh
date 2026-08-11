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
  });

  final int id;
  final String title;
  final String partner;
  final String priceFcfa;
  final int priceFcfaValue;
  final String description;
  final bool deliveryAvailable;
  final int deliveryFeeFcfa;
}
