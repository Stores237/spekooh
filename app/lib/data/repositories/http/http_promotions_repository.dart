import '../../../models/promotion.dart';
import '../../api_client.dart';
import '../promotions_repository.dart';

class HttpPromotionsRepository implements PromotionsRepository {
  HttpPromotionsRepository(this._client);
  final ApiClient _client;

  @override
  Future<List<Promotion>> getActivePromotions() async {
    final rows = await _client.get('/promotions/active/') as List;
    return rows
        .map((row) => Promotion(
              id: row['id'] as int,
              title: row['title'] as String,
              subtitle: row['subtitle'] as String? ?? '',
              sponsorName: row['sponsor_name'] as String? ?? '',
              iconName: row['icon_name'] as String? ?? '',
              ctaLabel: row['cta_label'] as String? ?? '',
              ctaUrl: row['cta_url'] as String? ?? '',
            ))
        .toList();
  }
}
