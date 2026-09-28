import '../../../models/feature_status.dart';
import '../../api_client.dart';
import '../feature_status_repository.dart';

class HttpFeatureStatusRepository implements FeatureStatusRepository {
  HttpFeatureStatusRepository(this._client);
  final ApiClient _client;

  // The answer changes only when the team ships a real payment provider, so
  // asking every time a payment screen opens would be wasted requests. A
  // failed lookup is never cached: the next screen asks again.
  static const _cacheFor = Duration(minutes: 10);
  FeatureStatus? _cached;
  DateTime? _cachedAt;

  @override
  Future<FeatureStatus> getFeatureStatus() async {
    final cachedAt = _cachedAt;
    if (_cached != null && cachedAt != null && DateTime.now().difference(cachedAt) < _cacheFor) {
      return _cached!;
    }
    try {
      final body = await _client.get('/status/features/') as Map<String, dynamic>;
      final status = FeatureStatus(paymentsLive: body['payments_live'] as bool? ?? false);
      _cached = status;
      _cachedAt = DateTime.now();
      return status;
    } catch (_) {
      return const FeatureStatus.unknown();
    }
  }
}
