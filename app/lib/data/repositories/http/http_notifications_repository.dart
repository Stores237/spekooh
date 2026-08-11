import 'package:flutter/material.dart';

import '../../../models/notification_item.dart';
import '../../../widgets/icon_chip.dart';
import '../../api_client.dart';
import '../notifications_repository.dart';

class HttpNotificationsRepository implements NotificationsRepository {
  HttpNotificationsRepository(this._client);
  final ApiClient _client;

  static const _iconByKind = {
    'ONBOARDING': Icons.auto_awesome_outlined,
    'SUBMISSION_STATUS': Icons.check,
    'CREDIT_AWARDED': Icons.stars_outlined,
    'GENERIC': Icons.notifications_none,
  };

  static const _tintByKind = {
    'ONBOARDING': IconChipTint.amber,
    'SUBMISSION_STATUS': IconChipTint.green,
    'CREDIT_AWARDED': IconChipTint.blue,
    'GENERIC': IconChipTint.blue,
  };

  static String _timeAgo(String isoTimestamp) {
    final date = DateTime.tryParse(isoTimestamp);
    if (date == null) return '';
    final diff = DateTime.now().toUtc().difference(date.toUtc());
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  }

  @override
  Future<List<NotificationItem>> getNotifications() async {
    final rows = await _client.get('/notifications/') as List;
    return rows.map((row) {
      final kind = row['kind'] as String;
      return NotificationItem(
        id: row['id'] as int,
        icon: _iconByKind[kind] ?? Icons.notifications_none,
        tint: _tintByKind[kind] ?? IconChipTint.blue,
        title: row['title'] as String,
        body: row['body'] as String,
        time: _timeAgo(row['created_at'] as String),
        isRead: row['is_read'] as bool? ?? false,
      );
    }).toList();
  }

  @override
  Future<void> markAllRead() => _client.post('/notifications/mark-all-read/');
}
