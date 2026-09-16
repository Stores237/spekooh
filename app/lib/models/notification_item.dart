import 'package:flutter/material.dart';
import '../widgets/icon_chip.dart';

class NotificationItem {
  const NotificationItem({
    this.id = 0,
    required this.icon,
    required this.tint,
    required this.title,
    required this.body,
    required this.time,
    this.isRead = false,
    this.link = '',
  });

  final int id;
  final IconData icon;
  final IconChipTint tint;
  final String title;
  final String body;
  final String time;
  final bool isRead;

  /// Opaque app route, e.g. "qr-vault/7" (QR Vault, 2026-09-16) — mirrors
  /// apps.notifications.models.Notification.link 1:1. Blank means this
  /// notification has nowhere further to navigate to.
  final String link;
}
