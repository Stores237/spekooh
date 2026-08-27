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
