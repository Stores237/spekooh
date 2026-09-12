import '../../api_client.dart';
import '../assistant_repository.dart';

class HttpAssistantRepository implements AssistantRepository {
  HttpAssistantRepository(this._client);
  final ApiClient _client;

  static const _path = '/ai/assistant/chat/';

  @override
  Future<ChatReply> sendMessage(List<ChatMessage> messages) async {
    try {
      final row = await _client.post(_path, body: {
        'messages': messages.map((m) => {'role': m.role, 'content': m.content}).toList(),
      }) as Map<String, dynamic>;
      return ChatReply(content: row['content'] as String, quotaRemaining: row['quota_remaining'] as int?);
    } on ApiException catch (e) {
      if (e.statusCode == 429) throw const ChatQuotaExceededException();
      rethrow;
    }
  }

  @override
  Stream<ChatStreamEvent> streamMessage(List<ChatMessage> messages) async* {
    final frames = _client.postStream(_path, body: {
      'messages': messages.map((m) => {'role': m.role, 'content': m.content}).toList(),
    });
    try {
      await for (final frame in frames) {
        if (frame['error'] == true) {
          yield ChatStreamEvent.error(frame['detail'] as String? ?? 'AI chat is currently unavailable.');
          return;
        }
        if (frame['done'] == true) {
          yield ChatStreamEvent.done(frame['quota_remaining'] as int?);
          return;
        }
        final delta = frame['delta'] as String?;
        if (delta != null) yield ChatStreamEvent.delta(delta);
      }
    } on ApiException catch (e) {
      // Same 429 the non-streaming path can hit — always before any delta
      // arrives (the daily-quota check runs before Groq is ever called),
      // same reasoning as HttpPapersRepository.streamChatMessage.
      if (e.statusCode == 429) throw const ChatQuotaExceededException();
      rethrow;
    }
  }
}
