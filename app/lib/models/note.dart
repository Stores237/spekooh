import 'package:flutter/material.dart';
import '../widgets/icon_chip.dart';

class Note {
  const Note({this.id = 0, required this.title, required this.subtitle, required this.tint, required this.icon});
  final int id;
  final String title;
  final String subtitle;
  final IconChipTint tint;
  final IconData icon;
}
