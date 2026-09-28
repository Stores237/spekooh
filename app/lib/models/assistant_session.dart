import '../data/repositories/papers_repository.dart' show ChatMessage;

/// One saved conversation with the Spekooh Assistant. Kept on the phone only
/// (see AssistantHistoryStore): nothing about it is sent to or stored on the
/// server.
class AssistantSession {
  const AssistantSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
  });

  final String id;

  /// The first thing the student asked, shortened: enough to recognise the chat.
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatMessage> messages;

  /// Longest title kept; longer first messages are cut with an ellipsis.
  static const maxTitleLength = 48;

  static String titleFor(List<ChatMessage> messages) {
    final firstUser = messages.where((m) => m.role == 'user').map((m) => m.content.trim()).firstWhere(
          (text) => text.isNotEmpty,
          orElse: () => '',
        );
    final oneLine = firstUser.replaceAll(RegExp(r'\s+'), ' ');
    return oneLine.length <= maxTitleLength ? oneLine : '${oneLine.substring(0, maxTitleLength - 1).trimRight()}…';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
        'messages': [
          for (final message in messages) {'role': message.role, 'content': message.content},
        ],
      };

  /// Throws on anything malformed; the store treats that as "this entry is
  /// unreadable" and skips it rather than losing the whole history.
  factory AssistantSession.fromJson(Map<String, dynamic> json) => AssistantSession(
        id: json['id'] as String,
        title: json['title'] as String,
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
        updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
        messages: [
          for (final raw in json['messages'] as List)
            ChatMessage(role: (raw as Map)['role'] as String, content: raw['content'] as String),
        ],
      );
}
