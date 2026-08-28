import 'package:flutter/widgets.dart';

/// Registered on the app's MaterialApp (see main.dart) so any screen that
/// mixes in RouteAware can refresh itself when it becomes visible again
/// after a child route pops back to it — e.g. ProfileScreen refetching its
/// counts after returning from Settings, instead of showing whatever was
/// true (possibly 0 real submissions, before a paper existed) the first
/// time it loaded (found from a live report, 2026-08-28: a real
/// contributor's published-paper count stayed 0 on Profile after the admin
/// published — Profile itself is always a fresh push and refetches fine,
/// but popping back onto an already-open Profile from a screen pushed on
/// top of it, e.g. Settings, previously never refreshed).
final profileRouteObserver = RouteObserver<PageRoute<void>>();
