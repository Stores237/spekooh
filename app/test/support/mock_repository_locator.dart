import 'package:spekooh/data/auth_session.dart';
import 'package:spekooh/data/repositories/forum_repository.dart';
import 'package:spekooh/data/repositories/notes_repository.dart';
import 'package:spekooh/data/repositories/notifications_repository.dart';
import 'package:spekooh/data/repositories/papers_repository.dart';
import 'package:spekooh/data/repositories/profile_repository.dart';
import 'package:spekooh/data/repositories/quizzes_repository.dart';
import 'package:spekooh/data/repositories/shop_repository.dart';
import 'package:spekooh/data/repository_locator.dart';

import 'fake_auth_session.dart';

/// A [RepositoryLocator] fully backed by Mock*Repository implementations —
/// for widget tests, which have no backend to talk to. Also installs the
/// same fake session as [AuthSession.instance] so login and repository
/// mocking stay consistent without two separate setup calls.
RepositoryLocator buildMockRepositoryLocator() {
  final fakeSession = buildFakeAuthSession();
  AuthSession.debugSetInstance(fakeSession);
  return RepositoryLocator(
    authSession: fakeSession,
    papers: MockPapersRepository(),
    notes: MockNotesRepository(),
    forum: MockForumRepository(),
    quizzes: MockQuizzesRepository(),
    notifications: MockNotificationsRepository(),
    shop: MockShopRepository(),
    profile: MockProfileRepository(),
  );
}
