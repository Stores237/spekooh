import 'package:flutter/material.dart';
import '../widgets/icon_chip.dart';

class Subject {
  const Subject({
    required this.key,
    required this.title,
    required this.tint,
    required this.icon,
    required this.code,
  });

  final String key;
  final String title;
  final IconChipTint tint;
  final IconData icon;
  final String code;
}
