import 'package:flutter/material.dart';
import '../../data/repositories/forum_repository.dart';
import '../../data/repository_locator.dart';
import '../../models/forum_post.dart';
import '../../sheets/ask_forum_post_sheet.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_theme.dart';
import '../../widgets/spekooh_avatar.dart';
import '../../widgets/spekooh_badge.dart';
import 'forum_post_detail_screen.dart';

/// Ported from ui_kits/spekooh-app/ForumScreen.jsx. One of the 5 bottom
/// tabs — lives directly in RootShell's IndexedStack, not pushed.
class ForumScreen extends StatefulWidget {
  ForumScreen({super.key, ForumRepository? repository})
    : repository = repository ?? RepositoryLocator.instance.forum;

  final ForumRepository repository;

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  late Future<List<ForumPost>> _postsFuture = widget.repository.getPosts();
  int _filter = 0;
  static const _filters = ['All', 'My subjects', 'Unanswered', 'Solved'];

  void _reload() => setState(() {
        _postsFuture = widget.repository.getPosts();
      });

  Future<void> _openAsk() async {
    final created = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AskForumPostSheet(repository: widget.repository),
    );
    if (created != null) _reload();
  }

  Future<void> _openPost(ForumPost post) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ForumPostDetailScreen(post: post, repository: widget.repository),
      ),
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceBg,
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPad,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.space2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Forum',
                        style: TextStyle(
                          fontFamily: plusJakartaSansFamily,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Row(
                        children: [
                          Icon(Icons.search),
                          SizedBox(width: 10),
                          Icon(Icons.notifications_none),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  SizedBox(
                    height: 32,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filters.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final active = i == _filter;
                        return GestureDetector(
                          onTap: () => setState(() => _filter = i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.ink900
                                  : AppColors.white,
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: active ? null : AppShadows.card,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _filters[i],
                              style: TextStyle(
                                fontFamily: plusJakartaSansFamily,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: active
                                    ? AppColors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  Expanded(
                    child: FutureBuilder<List<ForumPost>>(
                      future: _postsFuture,
                      builder: (context, snapshot) {
                        final posts = snapshot.data ?? const [];
                        return ListView.separated(
                          itemCount: posts.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.space3),
                          itemBuilder: (context, i) => GestureDetector(
                            onTap: () => _openPost(posts[i]),
                            child: _PostCard(post: posts[i]),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: AppSpacing.space5,
              right: AppSpacing.screenPad,
              child: GestureDetector(
                onTap: _openAsk,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.gold400, AppColors.gold700],
                    ),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: AppShadows.button,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 13,
                    ),
                    child: Text(
                      '+ Ask',
                      style: TextStyle(
                        fontFamily: plusJakartaSansFamily,
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post});
  final ForumPost post;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const SpekoohAvatar(size: 28),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.name,
                        style: TextStyle(
                          fontFamily: plusJakartaSansFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        post.time,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SpekoohBadge(text: post.tag, tone: SpekoohBadgeTone.blue),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            post.title,
            style: TextStyle(
              fontFamily: plusJakartaSansFamily,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            post.body,
            style: TextStyle(
              fontFamily: plusJakartaSansFamily,
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '↑ ${post.upvotes}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(width: 14),
              const Icon(
                Icons.chat_bubble_outline,
                size: 14,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                '${post.answers} answers',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
