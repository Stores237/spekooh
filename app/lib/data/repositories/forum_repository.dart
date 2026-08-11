import '../../models/forum_post.dart';
import '../mock/mock_forum_posts.dart';

abstract class ForumRepository {
  Future<List<ForumPost>> getPosts();
  Future<ForumPost> createPost({required String tag, required String title, required String body});
  Future<List<ForumReply>> getReplies(int postId);
  Future<ForumReply> addReply(int postId, String body);
  Future<bool> toggleUpvote(int postId);
}

class MockForumRepository implements ForumRepository {
  final List<ForumPost> _posts = List.of(mockForumPosts);
  final Map<int, List<ForumReply>> _replies = {};
  final Set<int> _upvoted = {};
  int _nextId = 1000;

  @override
  Future<List<ForumPost>> getPosts() => Future.value(List.unmodifiable(_posts));

  @override
  Future<ForumPost> createPost({required String tag, required String title, required String body}) async {
    final post = ForumPost(id: _nextId++, name: 'You', time: 'just now', tag: tag, title: title, body: body, upvotes: 0, answers: 0);
    _posts.insert(0, post);
    return post;
  }

  @override
  Future<List<ForumReply>> getReplies(int postId) => Future.value(List.unmodifiable(_replies[postId] ?? const []));

  @override
  Future<ForumReply> addReply(int postId, String body) async {
    final reply = ForumReply(id: _nextId++, authorName: 'You', body: body, time: 'just now');
    _replies.putIfAbsent(postId, () => []).add(reply);
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index != -1) {
      final p = _posts[index];
      _posts[index] = ForumPost(
        id: p.id, name: p.name, time: p.time, tag: p.tag, title: p.title, body: p.body,
        upvotes: p.upvotes, answers: p.answers + 1, hasUpvoted: p.hasUpvoted,
      );
    }
    return reply;
  }

  @override
  Future<bool> toggleUpvote(int postId) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return false;
    final p = _posts[index];
    final nowUpvoted = !_upvoted.contains(postId);
    if (nowUpvoted) {
      _upvoted.add(postId);
    } else {
      _upvoted.remove(postId);
    }
    _posts[index] = ForumPost(
      id: p.id, name: p.name, time: p.time, tag: p.tag, title: p.title, body: p.body,
      upvotes: p.upvotes + (nowUpvoted ? 1 : -1), answers: p.answers, hasUpvoted: nowUpvoted,
    );
    return nowUpvoted;
  }
}
