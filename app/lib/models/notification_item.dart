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
  });

  final int id;
  final IconData icon;
  final IconChipTint tint;
  final String title;
  final String body;
  final String time;
  final bool isRead;
}
