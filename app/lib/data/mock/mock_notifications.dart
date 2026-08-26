import '../../models/notification_item.dart';
import '../../widgets/icon_chip.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const mockNotifications = [
  NotificationItem(
    id: 1,
    icon: LucideIcons.sparkles,
    tint: IconChipTint.amber,
    title: 'Welcome to Spekooh 🎉',
    body: 'You\'ve got 7 days free: all marking guides, unlimited AI assistant and downloads.',
    time: '12 min ago',
  ),
  NotificationItem(
    id: 2,
    icon: LucideIcons.check,
    tint: IconChipTint.green,
    title: 'Physics paper published',
    body: 'Your submission\'s marking guide is live. You earned 150 credits.',
    time: '1 day ago',
  ),
];
