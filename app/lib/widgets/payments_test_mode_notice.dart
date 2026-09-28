import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../data/repository_locator.dart';
import '../l10n/app_localizations.dart';
import '../models/feature_status.dart';
import 'spekooh_banner.dart';

/// "Test mode: payments aren't live yet" — shown right where money changes
/// hands (Pro subscription, guide and download unlocks, pamphlet purchases),
/// because those flows run for real against a simulated payment provider:
/// they behave exactly like the real thing but no money moves.
///
/// The server decides (apps.core.feature_status), so once a real provider is
/// wired in the notice disappears on its own, with no app release. Until the
/// server has answered (or if it can't be reached) it is shown: a missing
/// warning on a fake payment is the worse mistake.
class PaymentsTestModeNotice extends StatefulWidget {
  const PaymentsTestModeNotice({super.key});

  @override
  State<PaymentsTestModeNotice> createState() => _PaymentsTestModeNoticeState();
}

class _PaymentsTestModeNoticeState extends State<PaymentsTestModeNotice> {
  late final Future<FeatureStatus> _status = RepositoryLocator.instance.featureStatus.getFeatureStatus();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<FeatureStatus>(
      future: _status,
      initialData: const FeatureStatus.unknown(),
      builder: (context, snapshot) {
        if (snapshot.data?.paymentsLive ?? false) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SpekoohBanner(
            tone: SpekoohBannerTone.blue,
            icon: const Icon(LucideIcons.flaskConical),
            message: l10n.paymentsTestModeNotice,
          ),
        );
      },
    );
  }
}
