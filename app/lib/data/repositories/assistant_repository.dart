import 'papers_repository.dart' show ChatMessage, ChatQuotaExceededException, ChatReply, ChatStreamEvent;

export 'papers_repository.dart' show ChatMessage, ChatQuotaExceededException, ChatReply, ChatStreamEvent;

/// "Spekooh Assistant" — the general-purpose counterpart to
/// [PapersRepository]'s chat methods (apps.ai.views.AssistantChatView).
/// Real, dedicated interface rather than bolting paper-less overloads onto
/// PapersRepository: this talks to a genuinely separate backend endpoint
/// with no paper/OCR concept at all, and reuses [ChatMessage]/[ChatReply]/
/// [ChatStreamEvent]/[ChatQuotaExceededException] as-is (re-exported above)
/// since none of those types carry anything paper-specific to begin with.
///
/// Real bug this replaces (2026-09-12): the "Spekooh Assistant" FAB shown
/// throughout the app (app/lib/widgets/ai_assistant_fab.dart) opened a
/// fully static bottom sheet — no controller, no tap handlers, nothing
/// wired to any repository at all. Owner-reported: "the spekooh Assistant
/// don't work at all," confirmed true by reading the widget before this
/// existed.
abstract class AssistantRepository {
  /// Real accounts only (server-side gate — see AssistantChatView), same
  /// shared daily quota as [ChatReply.quotaRemaining] on the per-paper
  /// chat (one "Lane B chat" allowance across both surfaces, not a
  /// separate pool — see apps.ai.quota's own docstring).
  Future<ChatReply> sendMessage(List<ChatMessage> messages);

  /// Streaming counterpart to [sendMessage] — same wire-format/error
  /// framing as PapersRepository.streamChatMessage; see that method's own
  /// doc comment for why a failure can arrive as an in-band
  /// [ChatStreamEvent.errorDetail] instead of a thrown exception once
  /// deltas have already started.
  Stream<ChatStreamEvent> streamMessage(List<ChatMessage> messages);
}

class MockAssistantRepository implements AssistantRepository {
  ChatReply mockReply = const ChatReply(content: 'A real reply.');
  Object? mockError;
  final List<List<ChatMessage>> calls = [];

  /// Set to exercise a real multi-chunk stream (each string becomes one
  /// [ChatStreamEvent.delta]) instead of delivering [mockReply]'s whole
  /// content as a single delta.
  List<String>? mockStreamDeltas;

  /// Set to make [streamMessage] emit a real [ChatStreamEvent.errorDetail]
  /// frame (a failure once streaming has already started) instead of
  /// [mockError]'s thrown exception (a failure before anything streams).
  String? mockStreamErrorDetail;

  @override
  Future<ChatReply> sendMessage(List<ChatMessage> messages) async {
    calls.add(messages);
    final error = mockError;
    if (error != null) throw error;
    return mockReply;
  }

  @override
  Stream<ChatStreamEvent> streamMessage(List<ChatMessage> messages) async* {
    calls.add(messages);
    final error = mockError;
    if (error != null) throw error;
    for (final delta in mockStreamDeltas ?? [mockReply.content]) {
      yield ChatStreamEvent.delta(delta);
    }
    final streamError = mockStreamErrorDetail;
    if (streamError != null) {
      yield ChatStreamEvent.error(streamError);
      return;
    }
    yield ChatStreamEvent.done(mockReply.quotaRemaining);
  }
}
