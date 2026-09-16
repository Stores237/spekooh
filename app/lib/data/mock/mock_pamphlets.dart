import '../../models/pamphlet.dart';

const mockFeaturedPamphlet = Pamphlet(
  title: 'Probatoire Philosophy Pamphlet',
  partner: 'Librairie Centrale',
  priceFcfa: '7,500',
  subjectTitle: 'Philosophie',
  academicLevel: 'Probatoire',
);

const mockPamphlets = [
  mockFeaturedPamphlet,
  Pamphlet(
    title: 'GCE A Level Further Maths Pack',
    partner: 'Presbook Bookshop',
    priceFcfa: '6,000',
    subjectTitle: 'Further Maths',
    academicLevel: 'A Level',
  ),
  Pamphlet(
    title: 'Baccalauréat SVT Revision Guide',
    partner: 'Librairie Centrale',
    priceFcfa: '5,500',
    subjectTitle: 'SVT',
    academicLevel: 'Baccalauréat',
  ),
];

final mockPamphletOrders = [
  PamphletOrder(
    id: 1,
    pamphletTitle: mockFeaturedPamphlet.title,
    status: 'QR_ISSUED',
    amountPaid: 7500,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    qrToken: 'mock-qr-token-000001',
    qrRedeemUrl: 'https://spekooh-staging.onrender.com/redeem/mock-qr-token-000001/',
    partnerName: mockFeaturedPamphlet.partner,
    partnerLocation: 'Avenue Kennedy, Douala',
    partnerPhone: '670000099',
    partnerWhatsapp: '670000098',
  ),
];
