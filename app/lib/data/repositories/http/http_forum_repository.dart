import '../../../models/forum_post.dart';
import '../../api_client.dart';
import '../forum_repository.dart';

class HttpForumRepository implements ForumRepository {
  HttpForumRepository(this._client);
  final ApiClient _client;

  ForumPost _fromJson(Map<String, dynamic> row) => ForumPost(
        id: row['id'] as int,
        name: row['author_name'] as String? ?? 'Anonymous',
        time: _timeAgo(row['created_at'] as String),
        tag: row['tag'] as String,
        title: row['title'] as String,
        body: row['body'] as String,
        upvotes: row['upvote_count'] as int? ?? 0,
        answers: row['reply_count'] as int? ?? 0,
        hasUpvoted: row['has_upvoted'] as bool? ?? false,
      );

  static String _timeAgo(String isoTimestamp) {
    final date = DateTime.tryParse(isoTimestamp);
    if (date == null) return '';
    final diff = DateTime.now().toUtc().difference(date.toUtc());
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Future<List<ForumPost>> getPosts() async {
    final rows = await _client.get('/forum/posts/') as List;
    return rows.map((row) => _fromJson(row as Map<String, dynamic>)).toList();
  }

  @override
  Future<ForumPost> createPost({required String tag, required String title, required String body}) async {
    final row = await _client.post('/forum/posts/', body: {'tag': tag, 'title': title, 'body': body});
    return _fromJson(row as Map<String, dynamic>);
  }

  @override
  Future<List<ForumReply>> getReplies(int postId) async {
    final rows = await _client.get('/forum/posts/$postId/replies/') as List;
    return rows.map((row) {
      return ForumReply(
        id: row['id'] as int,
        authorName: row['author_name'] as String? ?? 'Anonymous',
        body: row['body'] as String,
        time: _timeAgo(row['created_at'] as String),
      );
    }).toList();
  }

  @override
  Future<ForumReply> addReply(int postId, String body) async {
    final row = await _client.post('/forum/posts/$postId/replies/', body: {'body': body});
    return ForumReply(
      id: row['id'] as int,
      authorName: row['author_name'] as String? ?? 'You',
      body: row['body'] as String,
      time: _timeAgo(row['created_at'] as String),
    );
  }

  @override
  Future<bool> toggleUpvote(int postId) async {
    final row = await _client.post('/forum/posts/$postId/upvote/');
    return row['has_upvoted'] as bool;
  }
}
