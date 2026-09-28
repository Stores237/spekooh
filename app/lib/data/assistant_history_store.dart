import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/assistant_session.dart';
import 'auth_session.dart';
import 'offline_file_store.dart';

/// The Spekooh Assistant's saved conversations, kept **on this phone only**,
/// one file per signed-in account, so a second account on the same phone
/// never sees the first one's chats. Nothing is sent to the server: the
/// history is a convenience for the student, not data Spekooh collects.
///
/// Storage goes through [OfflineFileStore], the same seam the offline papers
/// use, so tests run against [InMemoryOfflineFileStore].
///
/// It must never get in the way of chatting: every storage failure (no
/// storage plugin in a test, a full disk, a damaged file) is swallowed and
/// looks like an empty history rather than an error.
class AssistantHistoryStore {
  AssistantHistoryStore({
    OfflineFileStore? fileStore,
    String? Function()? currentUserId,
    this.maxSessions = 30,
    this.maxMessagesPerSession = 200,
  })  : _files = fileStore ?? const LocalOfflineFileStore(subdirectory: 'assistant_history'),
        _currentUserId = currentUserId ?? (() => AuthSession.instance.currentUserId);

  static AssistantHistoryStore instance = AssistantHistoryStore();

  @visibleForTesting
  static void debugSetInstance(AssistantHistoryStore store) => instance = store;

  final OfflineFileStore _files;
  final String? Function() _currentUserId;

  /// Oldest chats beyond this are dropped when a new one is saved.
  final int maxSessions;

  /// A single very long chat keeps only its most recent messages.
  final int maxMessagesPerSession;

  // The account id is used in a file name: keep only characters that are
  // safe there (real ids are UUIDs).
  String get _path {
    final id = (_currentUserId() ?? 'anonymous').replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return 'sessions_$id.json';
  }

  /// Newest first.
  Future<List<AssistantSession>> list() async {
    final sessions = await _read();
    sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sessions;
  }

  /// Adds the session, or replaces the one with the same id.
  Future<void> save(AssistantSession session) async {
    final trimmed = session.messages.length > maxMessagesPerSession
        ? session.messages.sublist(session.messages.length - maxMessagesPerSession)
        : session.messages;
    final sessions = await _read();
    sessions.removeWhere((existing) => existing.id == session.id);
    sessions.add(AssistantSession(
      id: session.id,
      title: session.title,
      createdAt: session.createdAt,
      updatedAt: session.updatedAt,
      messages: trimmed,
    ));
    sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    await _write(sessions.take(maxSessions).toList());
  }

  Future<void> delete(String id) async {
    final sessions = await _read();
    sessions.removeWhere((session) => session.id == id);
    await _write(sessions);
  }

  /// Removes every saved chat for the signed-in account.
  Future<void> clear() async {
    try {
      await _files.delete(_path);
    } catch (_) {
      // Nothing saved, or storage unavailable: either way there is nothing left.
    }
  }

  Future<List<AssistantSession>> _read() async {
    try {
      final bytes = await _files.readBytes(_path);
      if (bytes == null) return [];
      final raw = jsonDecode(utf8.decode(bytes)) as List;
      final sessions = <AssistantSession>[];
      for (final entry in raw) {
        try {
          sessions.add(AssistantSession.fromJson(entry as Map<String, dynamic>));
        } catch (_) {
          // One unreadable entry must not cost the student every other chat.
        }
      }
      return sessions;
    } catch (_) {
      return [];
    }
  }

  Future<void> _write(List<AssistantSession> sessions) async {
    try {
      await _files.writeBytes(_path, utf8.encode(jsonEncode([for (final s in sessions) s.toJson()])));
    } catch (_) {
      // Saving is best effort; losing one save must never break the chat.
    }
  }
}
