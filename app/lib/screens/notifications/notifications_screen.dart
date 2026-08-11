import 'package:flutter/material.dart';
import '../../data/repositories/notifications_repository.dart';
import '../../data/repository_locator.dart';
import '../../models/notification_item.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../../widgets/icon_chip.dart';
import '../common/circular_back_button.dart';

/// Ported from ui_kits/spekooh-app/NotificationsScreen.jsx.
class NotificationsScreen extends StatefulWidget {
  NotificationsScreen({super.key, NotificationsRepository? repository})
      : repository = repository ?? RepositoryLocator.instance.notifications;

  final NotificationsRepository repository;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final Future<List<NotificationItem>> _future = widget.repository.getNotifications();

  @override
  void initState() {
    super.initState();
    widget.repository.markAllRead();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.space2),
              Row(
                children: [
                  CircularBackButton(onTap: () => Navigator.of(context).pop()),
                  const SizedBox(width: AppSpacing.space3),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Notifications', style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 19, color: AppColors.textPrimary)),
                      Text('All caught up', style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space4),
              Expanded(
                child: FutureBuilder<List<NotificationItem>>(
                  future: _future,
                  builder: (context, snapshot) {
                    final items = snapshot.data ?? const [];
                    return ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.space3),
                      itemBuilder: (context, i) {
                        final n = items[i];
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: AppShadows.card,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              IconChip(icon: n.icon, tint: n.tint, size: 36),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(n.title, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
                                    const SizedBox(height: 2),
                                    Text(n.body, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
                                    const SizedBox(height: 4),
                                    Text(n.time, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
