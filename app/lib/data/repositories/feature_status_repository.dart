import '../../models/feature_status.dart';

abstract class FeatureStatusRepository {
  /// Never throws: if the server can't be reached the answer is
  /// [FeatureStatus.unknown], which errs towards showing the notices.
  Future<FeatureStatus> getFeatureStatus();
}

class MockFeatureStatusRepository implements FeatureStatusRepository {
  /// Defaults to what is actually true today: payments are simulated.
  MockFeatureStatusRepository({this.status = const FeatureStatus(paymentsLive: false)});

  FeatureStatus status;

  @override
  Future<FeatureStatus> getFeatureStatus() => Future.value(status);
}
