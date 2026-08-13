import 'package:flutter/material.dart';
import '../data/auth_session.dart';
import '../data/repository_locator.dart';
import '../models/pamphlet.dart';
import '../models/paper_entry.dart';
import '../sheets/auth_sheet.dart';
import '../sheets/pamphlet_sheet.dart';
import '../sheets/paywall_sheet.dart';
import '../theme/app_colors.dart';
import '../widgets/ai_assistant_fab.dart';
import '../widgets/bottom_nav.dart';
import '../screens/notes/notes_screen.dart';
import '../screens/forum/forum_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/logged_in_home_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/papers/paper_detail_screen.dart';
import '../screens/papers/papers_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/quizzes/quizzes_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/shop/shop_screen.dart';
import '../screens/submit/submit_screen.dart';

/// Single source of truth for cross-screen state: which bottom tab is
/// active, and whether the user is "logged in" (a local boolean flipped by
/// the Settings screen's Log in button — no real auth yet). Overlay screens
/// (Settings, Profile, Notifications, Notes, Shop, PaperDetail) are reached
/// via plain `Navigator.push` from wherever their entry-point CTA lives, not
/// routed through this shell — see the navigation-graph stage for those.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => RootShellState();
}

class RootShellState extends State<RootShell> {
  int _activeTab = 0;
  bool _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn;

  @override
  void initState() {
    super.initState();
    AuthSession.instance.addListener(_onAuthChanged);
    AuthSession.instance.bootstrap();
  }

  @override
  void dispose() {
    AuthSession.instance.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) setState(() => _isLoggedIn = AuthSession.instance.isLoggedIn);
  }

  void goToTab(int index) => setState(() => _activeTab = index);

  /// Flips to the logged-in variant and returns to the Home tab. Called
  /// directly by tests; in the real app it fires via [_onAuthChanged] once
  /// [AuthSheet] completes a real login/register against the backend.
  void login() => setState(() {
        _isLoggedIn = true;
        _activeTab = 0;
      });

  /// Clears the real session (AuthSession.logout()), pops back to the root
  /// tab view, and returns to Home — _onAuthChanged flips _isLoggedIn once
  /// the clear completes, swapping back to the guest Home/screens.
  Future<void> _logout(BuildContext context) async {
    await AuthSession.instance.logout();
    if (context.mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    setState(() => _activeTab = 0);
  }

  Future<void> _openAuthSheet(BuildContext context) async {
    final success = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AuthSheet(),
    );
    if (success == true) {
      login();
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  void _openSettings(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SettingsScreen(
            onLogin: () => _openAuthSheet(context),
            onLogout: () => _logout(context),
            onOpenPaywall: () => _openPaywall(context),
          ),
        ),
      );

  void _openProfile(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ProfileScreen(onOpenSettings: () => _openSettings(context), onLogin: () => _openAuthSheet(context))),
      );

  void _openNotes(BuildContext context) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => NotesScreen()));

  void _openShop(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ShopScreen(onOpenPamphlet: (pamphlet) => _openPamphletSheet(context, pamphlet))),
      );

  void _openNotifications(BuildContext context) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => NotificationsScreen()));

  void _openPaperDetail(BuildContext context, [PaperSelection? paper]) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PaperDetailScreen(paper: paper)),
      );

  void _openPaperEntryDetail(BuildContext context, PaperEntry entry) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PaperDetailScreen(paperEntry: entry)),
      );

  void _openPaywall(BuildContext context) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => PaywallSheet(),
      );

  Future<void> _openPamphlet(BuildContext context) async {
    final pamphlet = await RepositoryLocator.instance.shop.getFeaturedPamphlet();
    if (!context.mounted) return;
    _openPamphletSheet(context, pamphlet);
  }

  void _openPamphletSheet(BuildContext context, Pamphlet pamphlet) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => PamphletSheet(pamphlet: pamphlet),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceBg,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _activeTab,
          children: [
            Builder(builder: _buildHomeTab),
            Builder(
              builder: (context) => PapersScreen(onOpenPaper: (paper) => _openPaperDetail(context, paper)),
            ),
            SubmitScreen(),
            ForumScreen(),
            QuizzesScreen(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNav(
        active: _activeTab,
        onChanged: goToTab,
        items: const [
          SpekoohNavItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          SpekoohNavItem(icon: Icon(Icons.description_outlined), label: 'Papers'),
          SpekoohNavItem(icon: Icon(Icons.upload_outlined), center: true),
          SpekoohNavItem(icon: Icon(Icons.chat_bubble_outline), label: 'Forum'),
          SpekoohNavItem(icon: Icon(Icons.bolt_outlined), label: 'Quizzes'),
        ],
      ),
      floatingActionButton: _isLoggedIn ? const AIAssistantFab() : null,
    );
  }

  Widget _buildHomeTab(BuildContext context) {
    if (_isLoggedIn) {
      return LoggedInHomeScreen(
        onOpenSettings: () => _openSettings(context),
        onOpenProfile: () => _openProfile(context),
        onOpenNotes: () => _openNotes(context),
        onOpenShop: () => _openShop(context),
        onOpenNotifications: () => _openNotifications(context),
        onOpenSubmit: () => goToTab(2),
        onOpenPapers: () => goToTab(1),
        onOpenForum: () => goToTab(3),
        onOpenQuizzes: () => goToTab(4),
        onOpenPaywall: () => _openPaywall(context),
      );
    }
    return HomeScreen(
      onOpenSettings: () => _openSettings(context),
      onOpenProfile: () => _openProfile(context),
      onOpenNotes: () => _openNotes(context),
      onOpenShop: () => _openShop(context),
      onOpenPaper: (entry) => _openPaperEntryDetail(context, entry),
      onOpenPamphlet: () => _openPamphlet(context),
      onOpenPaywall: () => _openPaywall(context),
    );
  }
}
