class ForumPost {
  const ForumPost({
    this.id = 0,
    required this.name,
    required this.time,
    required this.tag,
    required this.title,
    required this.body,
    required this.upvotes,
    required this.answers,
    this.hasUpvoted = false,
  });

  final int id;
  final String name;
  final String time;
  final String tag;
  final String title;
  final String body;
  final int upvotes;
  final int answers;
  final bool hasUpvoted;
}

class ForumReply {
  const ForumReply({required this.id, required this.authorName, required this.body, required this.time});
  final int id;
  final String authorName;
  final String body;
  final String time;
}
