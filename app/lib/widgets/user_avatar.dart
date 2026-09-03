import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// The one real avatar-rendering widget in the app — shows the user's real
/// photo when one is set, and their name's first letter otherwise. Extracted
/// 2026-09-03 after a real bug: Home's own header avatar was a separate,
/// simplified copy of this same idea that never actually checked
/// [SpekoohUser.avatarUrl] at all, so a set-and-visible-on-Profile avatar
/// never showed up on Home — exactly the kind of drift a second copy of the
/// same logic invites. Profile's own avatar circle still wraps this (it
/// layers on tap-to-change, the picked-but-not-yet-uploaded preview, and the
/// uploading spinner overlay, none of which apply anywhere else this is used).
///
/// Always shows something honest: the letter is the real default for a null
/// [avatarUrl], and also covers a still-loading or failed fetch (a network
/// image draws nothing at all in either of those states with no
/// loadingBuilder/errorBuilder — see the profile_screen_test.dart/
/// api_client_error_test.dart cases this was hardened against, 2026-09-02).
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.name, this.avatarUrl, this.size = 38});

  final String name;
  final String? avatarUrl;
  final double size;

  Widget _initial() => Text(
        name.isEmpty ? '?' : name[0].toUpperCase(),
        style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: size * 0.42, color: AppColors.gold700),
      );

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl;
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.gold200),
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      child: url == null
          ? _initial()
          : ClipOval(
              child: Image.network(
                url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) => progress == null ? child : _initial(),
                errorBuilder: (context, error, stackTrace) => _initial(),
              ),
            ),
    );
  }
}
