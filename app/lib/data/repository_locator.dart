import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'auth_session.dart';
import 'repositories/forum_repository.dart';
import 'repositories/http/http_forum_repository.dart';
import 'repositories/http/http_notes_repository.dart';
import 'repositories/http/http_notifications_repository.dart';
import 'repositories/http/http_papers_repository.dart';
import 'repositories/http/http_profile_repository.dart';
import 'repositories/http/http_quizzes_repository.dart';
import 'repositories/http/http_shop_repository.dart';
import 'repositories/notes_repository.dart';
import 'repositories/notifications_repository.dart';
import 'repositories/papers_repository.dart';
import 'repositories/profile_repository.dart';
import 'repositories/quizzes_repository.dart';
import 'repositories/shop_repository.dart';

/// Holds the shared [ApiClient]/[AuthSession] pair and every domain
/// repository — the single place that switches screens from Mock* to
/// Http*. Screens pull from [RepositoryLocator.instance] instead of
/// constructing Mock*Repository() inline.
///
/// Swappable via [debugSetInstance] for widget tests, which have no
/// backend to talk to — see test/support/mock_repository_locator.dart.
class RepositoryLocator {
  RepositoryLocator({
    AuthSession? authSession,
    ApiClient? apiClient,
    PapersRepository? papers,
    NotesRepository? notes,
    ForumRepository? forum,
    QuizzesRepository? quizzes,
    NotificationsRepository? notifications,
    ShopRepository? shop,
    ProfileRepository? profile,
  })  : authSession = authSession ?? AuthSession.instance,
        apiClient = apiClient ?? ApiClient(authSession: authSession ?? AuthSession.instance) {
    this.papers = papers ?? HttpPapersRepository(this.apiClient);
    this.notes = notes ?? HttpNotesRepository(this.apiClient);
    this.forum = forum ?? HttpForumRepository(this.apiClient);
    this.quizzes = quizzes ?? HttpQuizzesRepository(this.apiClient);
    this.notifications = notifications ?? HttpNotificationsRepository(this.apiClient);
    this.shop = shop ?? HttpShopRepository(this.apiClient);
    this.profile = profile ?? HttpProfileRepository(this.apiClient);
  }

  static RepositoryLocator instance = RepositoryLocator();

  @visibleForTesting
  static void debugSetInstance(RepositoryLocator locator) => instance = locator;

  final AuthSession authSession;
  final ApiClient apiClient;

  late final PapersRepository papers;
  late final NotesRepository notes;
  late final ForumRepository forum;
  late final QuizzesRepository quizzes;
  late final NotificationsRepository notifications;
  late final ShopRepository shop;
  late final ProfileRepository profile;
}
