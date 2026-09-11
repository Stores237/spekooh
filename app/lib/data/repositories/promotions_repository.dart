import '../../models/promotion.dart';

abstract class PromotionsRepository {
  /// Always safe to call, never throws for "nothing to show" — an empty
  /// list is the normal, honest state until a real sponsor deal exists.
  /// See apps.promotions.models.Promotion's own doc comment on the backend.
  Future<List<Promotion>> getActivePromotions();
}

class MockPromotionsRepository implements PromotionsRepository {
  /// Empty by default — real usage starts with nothing sponsored yet. Set
  /// [seed] in a test to exercise a real promotion showing.
  MockPromotionsRepository({List<Promotion> seed = const []}) : _promotions = seed;

  final List<Promotion> _promotions;

  @override
  Future<List<Promotion>> getActivePromotions() => Future.value(_promotions);
}
