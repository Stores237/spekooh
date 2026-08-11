import 'package:flutter/material.dart';
import '../../data/mock/mock_quizzes.dart';
import '../../data/repositories/quizzes_repository.dart';
import '../../data/repository_locator.dart';
import '../../models/quiz.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_theme.dart';
import '../../widgets/icon_chip.dart';
import '../../widgets/search_input.dart';
import '../../widgets/spekooh_avatar.dart';
import '../../widgets/spekooh_toggle.dart';
import '../../widgets/stat_row.dart';

/// Ported from ui_kits/spekooh-app/QuizzesScreen.jsx. One of the 5 bottom
/// tabs. QuizDetail is in-tab local state (`_openQuiz`), not a pushed
/// route — the source keeps it inside the same component, not a separate
/// screen/URL.
class QuizzesScreen extends StatefulWidget {
  QuizzesScreen({super.key, QuizzesRepository? repository}) : repository = repository ?? RepositoryLocator.instance.quizzes;

  final QuizzesRepository repository;

  @override
  State<QuizzesScreen> createState() => _QuizzesScreenState();
}

class _QuizzesScreenState extends State<QuizzesScreen> {
  late final Future<Quiz> _dailyFuture = widget.repository.getDailyChallenge();
  late final Future<List<Quiz>> _quizzesFuture = widget.repository.getQuizzes();
  late final Future<List<({String name, int rank, String quizzes})>> _leaderboardFuture =
      widget.repository.getLeaderboard();

  Quiz? _openQuiz;
  int _filter = 0;
  final _searchController = TextEditingController();
  String _query = '';

  static const _filters = ['All', 'Sciences', 'Arts', 'Commercial'];
  static const _iconByTitle = {
    'Biology quiz': (Icons.eco_outlined, IconChipTint.green),
    'Chemistry quizzes': (Icons.science_outlined, IconChipTint.purple),
    'Geography quizzes': (Icons.public_outlined, IconChipTint.amber),
    'Computer science': (Icons.memory_outlined, IconChipTint.blue),
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openQuizById(int id) async {
    final detail = await widget.repository.getQuizDetail(id);
    if (mounted) setState(() => _openQuiz = detail);
  }

  @override
  Widget build(BuildContext context) {
    if (_openQuiz != null) return _buildDetail(_openQuiz!);
    return _buildList();
  }

  Widget _buildDetail(Quiz quiz) {
    var timerOn = true;
    var hintsOn = true;
    var shuffleOn = false;
    final selectedAnswers = List<int?>.filled(quiz.questions.length, null);
    var isSubmitting = false;
    int? score;
    return Scaffold(
      backgroundColor: AppColors.surfaceBg,
      body: SafeArea(
        child: StatefulBuilder(
          builder: (context, setLocalState) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.space2),
                GestureDetector(
                  onTap: () => setState(() => _openQuiz = null),
                  child: const Icon(Icons.chevron_left),
                ),
                const SizedBox(height: AppSpacing.space2),
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(color: AppColors.gold50, borderRadius: BorderRadius.circular(16)),
                        alignment: Alignment.center,
                        child: Text('Σ', style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 26, color: AppColors.gold700)),
                      ),
                      const SizedBox(height: AppSpacing.space2),
                      Text(quiz.title, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 19, color: AppColors.textPrimary)),
                      const SizedBox(height: AppSpacing.space2),
                      Text(quiz.subtitle, textAlign: TextAlign.center, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                StatRow(stats: [
                  SpekoohStat(value: '${quiz.questionCount}', label: 'questions'),
                  SpekoohStat(value: quiz.suggestedTime, label: 'suggested'),
                  SpekoohStat(value: '${quiz.playedCount}', label: 'played'),
                ]),
                const SizedBox(height: AppSpacing.space4),
                Container(
                  decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.card),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _settingRow(Icons.timer_outlined, 'Timer 8:00', timerOn, (v) => setLocalState(() => timerOn = v)),
                      const Divider(height: 1),
                      _settingRow(Icons.lightbulb_outline, 'Hints  2 available', hintsOn, (v) => setLocalState(() => hintsOn = v)),
                      const Divider(height: 1),
                      _settingRow(Icons.shuffle, 'Shuffle questions', shuffleOn, (v) => setLocalState(() => shuffleOn = v)),
                    ],
                  ),
                ),
                if (quiz.questions.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.space5),
                  for (var qi = 0; qi < quiz.questions.length; qi++) ...[
                    Text(quiz.questions[qi].text, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                    const SizedBox(height: AppSpacing.space2),
                    for (var ci = 0; ci < quiz.questions[qi].choices.length; ci++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: score != null ? null : () => setLocalState(() => selectedAnswers[qi] = ci),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: selectedAnswers[qi] == ci ? AppColors.gold50 : AppColors.surfaceSunken,
                              border: Border.all(color: selectedAnswers[qi] == ci ? AppColors.gold400 : AppColors.borderSubtle),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(quiz.questions[qi].choices[ci], style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 13, color: AppColors.textPrimary)),
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.space3),
                  ],
                ],
                if (score != null) ...[
                  Text('You scored $score / ${quiz.questions.length}', textAlign: TextAlign.center, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary)),
                  const SizedBox(height: AppSpacing.space3),
                ],
                const SizedBox(height: AppSpacing.space5),
                GestureDetector(
                  onTap: (isSubmitting || score != null || quiz.questions.isEmpty)
                      ? null
                      : () async {
                          setLocalState(() => isSubmitting = true);
                          final result = await widget.repository.submitAttempt(
                            quiz.id,
                            selectedAnswers.map((a) => a ?? -1).toList(),
                          );
                          setLocalState(() {
                            isSubmitting = false;
                            score = result;
                          });
                        },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(color: AppColors.gold500, borderRadius: BorderRadius.circular(999)),
                    alignment: Alignment.center,
                    child: Text(
                      score != null ? 'Done' : (isSubmitting ? 'Submitting…' : 'Start quiz'),
                      style: TextStyle(fontFamily: plusJakartaSansFamily, color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space6),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _settingRow(IconData icon, String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 14, color: AppColors.textPrimary))),
          SpekoohToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildList() {
    return Scaffold(
      backgroundColor: AppColors.surfaceBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.space2),
              Text('Quiz', style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.textPrimary)),
              const SizedBox(height: AppSpacing.space4),
              FutureBuilder<Quiz>(
                future: _dailyFuture,
                builder: (context, snapshot) {
                  final daily = snapshot.data ?? mockDailyChallenge;
                  return GestureDetector(
                    onTap: () => _openQuizById(daily.id),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.ink900, borderRadius: BorderRadius.circular(18)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('DAILY CHALLENGE', style: TextStyle(color: AppColors.textOnDarkMuted, fontSize: 11)),
                              Text('Resets in 7h 23m', style: TextStyle(color: AppColors.textOnDarkMuted, fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(daily.title, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.white)),
                          const SizedBox(height: 2),
                          Text('${daily.questionCount} questions · ${daily.playedCount} students played', style: const TextStyle(color: AppColors.textOnDarkMuted, fontSize: 12)),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(color: AppColors.gold500, borderRadius: BorderRadius.circular(999)),
                            alignment: Alignment.center,
                            child: Text('Play daily challenge', style: TextStyle(fontFamily: plusJakartaSansFamily, color: AppColors.ink900, fontWeight: FontWeight.w800, fontSize: 14)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.space4),
              Row(
                children: [
                  Expanded(child: _modeCard(Icons.timer_outlined, 'Timed practice', 'Exam conditions')),
                  const SizedBox(width: AppSpacing.space2),
                  Expanded(child: _modeCard(Icons.shuffle, 'Revision mode', 'No timer, hints on')),
                ],
              ),
              const SizedBox(height: AppSpacing.space4),
              Container(
                decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.card),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _openQuiz = mockQuizDetail),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          children: [
                            const Icon(Icons.bolt_outlined),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Past-paper practice', style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                                  Text('Generated from submitted papers · every sector & level', style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        children: [
                          const Icon(Icons.emoji_events_outlined),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Friday Arena', style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                                Text('Live elimination quiz · everyone plays for prizes', style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.ink900, borderRadius: BorderRadius.circular(18)),
                child: FutureBuilder<List<({String name, int rank, String quizzes})>>(
                  future: _leaderboardFuture,
                  builder: (context, snapshot) {
                    final entries = snapshot.data ?? const [];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Top players', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                            const Text('See all', style: TextStyle(color: AppColors.textOnDarkMuted, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.space3),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: entries
                              .map((e) => Column(
                                    children: [
                                      SpekoohAvatar(name: e.name, rank: e.rank),
                                      const SizedBox(height: 6),
                                      Text(e.name, style: const TextStyle(color: AppColors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                                      Text(e.quizzes, style: const TextStyle(color: AppColors.textOnDarkMuted, fontSize: 10)),
                                    ],
                                  ))
                              .toList(),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.space6),
              Text('By subject', style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.textPrimary)),
              const SizedBox(height: AppSpacing.space3),
              SearchInput(placeholder: 'Search subjects...', controller: _searchController, onChanged: (v) => setState(() => _query = v)),
              const SizedBox(height: AppSpacing.space3),
              SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final active = i == _filter;
                    return GestureDetector(
                      onTap: () => setState(() => _filter = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: active ? AppColors.ink900 : AppColors.white,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: active ? null : AppShadows.card,
                        ),
                        alignment: Alignment.center,
                        child: Text(_filters[i], style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, fontWeight: FontWeight.w700, color: active ? AppColors.white : AppColors.textSecondary)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.space3),
              FutureBuilder<List<Quiz>>(
                future: _quizzesFuture,
                builder: (context, snapshot) {
                  final quizzes = (snapshot.data ?? const [])
                      .where((q) => q.title.toLowerCase().contains(_query.toLowerCase()))
                      .toList();
                  return Column(
                    children: [
                      for (final quiz in quizzes) ...[
                        GestureDetector(
                          onTap: () => _openQuizById(quiz.id),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.card),
                            child: Row(
                              children: [
                                IconChip(
                                  icon: _iconByTitle[quiz.title]?.$1 ?? quiz.icon,
                                  tint: _iconByTitle[quiz.title]?.$2 ?? IconChipTint.blue,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(quiz.title, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                                      Text(quiz.subtitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 12, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: AppColors.textTertiary),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space3),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeCard(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(18), boxShadow: AppShadows.card),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontFamily: plusJakartaSansFamily, fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
          Text(subtitle, style: TextStyle(fontFamily: plusJakartaSansFamily, fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
