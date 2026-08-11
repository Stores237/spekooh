import 'package:flutter/material.dart';

class Achievement {
  const Achievement({required this.icon, required this.label, required this.earned});
  final IconData icon;
  final String label;
  final bool earned;
}
