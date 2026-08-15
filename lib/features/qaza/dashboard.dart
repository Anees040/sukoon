import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sukoon/core/dates.dart';
import 'package:sukoon/core/l10n_ext.dart';
import 'package:sukoon/core/prefs.dart';
import 'package:sukoon/data/achievements.dart';
import 'package:sukoon/data/qaza_repository.dart';
import 'package:sukoon/features/common/widgets.dart';
import 'package:sukoon/features/qaza/achievements_wall.dart';
import 'package:sukoon/features/qaza/planner.dart';
import 'package:sukoon/features/qaza/wizard.dart';
import 'package:sukoon/l10n/gen/app_localizations.dart';
import 'package:sukoon/qaza/plan_math.dart';
import 'package:sukoon/theme.dart';

class QazaDashboard extends StatefulWidget {
  const QazaDashboard({super.key});

  @override
  State<QazaDashboard> createState() => _QazaDashboardState();
}

class _QazaDashboardState extends State<QazaDashboard> {
  List<QazaPrayerState> _state = [];
  Map<String, int> _todayByPrayer = {};
  Map<String, int> _dailyTotals = {};
  int _unlockedCount = 0;
  bool _loading = true;

  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 2));

  /// The last revision we saw — skip redundant reloads.
  int _lastQazaRevision = -1;

  @override
  void initState() {
    super.initState();
    _reload();
    QazaRepository.revision.addListener(_onQazaChanged);
  }

  @override
  void dispose() {
    QazaRepository.revision.removeListener(_onQazaChanged);
    _confetti.dispose();
    super.dispose();
  }

  /// Called whenever the qaza DB is mutated (from tracker or repay).
  void _onQazaChanged() {
    final rev = QazaRepository.revision.value;
    if (rev != _lastQazaRevision) {
      _lastQazaRevision = rev;
      _reload();
    }
  }

  Future<void> _reload() async {
    final from = dateKey(
        dateOnly(DateTime.now()).subtract(const Duration(days: 400)));
    final results = await Future.wait([
      QazaRepository.state(),
      QazaRepository.repaidOn(dateKey(DateTime.now())),
      QazaRepository.dailyTotalsSince(from),
      AchievementsRepository.unlocked(),
    ]);
    if (!mounted) return;
    setState(() {
      _state = results[0] as List<QazaPrayerState>;
      _todayByPrayer = results[1] as Map<String, int>;
      _dailyTotals = results[2] as Map<String, int>;
      _unlockedCount = (results[3] as Set<String>).length;
      _loading = false;
    });
  }

  Map<String, int> get _remaining =>
      {for (final s in _state) s.prayer: s.remaining};

  int get _planStreak {
    final owedTypes = _remaining.values.where((v) => v > 0).length;
    return planStreak(
      dailyTotals: _dailyTotals,
      requiredPerDay:
          Prefs.dailyTargetSets * (owedTypes == 0 ? 1 : owedTypes),
      today: DateTime.now(),
    );
  }

  Future<void> _repay(String prayer, int count) async {
    HapticFeedback.lightImpact();
    final res = await QazaRepository.repay(
        prayer, count, dateKey(DateTime.now()));
    if (res.applied <= 0) return;
    await _reload();

    // Achievements — unlock + celebrate exactly once each.
    final totals = await QazaRepository.totals();
    final fresh = await AchievementsRepository.evaluateAndUnlock(
      totalRepaid: totals.$2,
      totalInitial: totals.$1,
      planStreakDays: _planStreak,
    );
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);

    if (fresh.isNotEmpty) {
      _confetti.play();
      HapticFeedback.mediumImpact();
      await _reload();
      if (!mounted) return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(fresh.isNotEmpty
            ? l10n.achUnlockedSnack(achievementTitle(l10n, fresh.first))
            : l10n.qazaRepaidAction(
                res.applied, prayerName(l10n, prayer))),
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () async {
            await QazaRepository.undoRepay(res.logId!);
            await _reload();
          },
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;

    if (_loading) {
      return const SafeArea(
          child: Center(child: CircularProgressIndicator()));
    }

    final totalInitial =
        _state.fold(0, (a, s) => a + s.initialOwed);
    final totalRepaid = _state.fold(0, (a, s) => a + s.repaid);
    final totalRemaining = totalInitial - totalRepaid;
    final pct = totalInitial == 0 ? 1.0 : totalRepaid / totalInitial;
    final todayTotal =
        _todayByPrayer.values.fold(0, (a, b) => a + b);

    return SafeArea(
      child: Stack(
        children: [
          ListView(
            padding: kScreenPad,
            children: [
              Row(
                children: [
                  Expanded(
                      child: Text(l10n.tabQaza, style: t.titleLarge)),
                  TextButton.icon(
                    icon: const Icon(Icons.calculate_outlined, size: 18),
                    label: Text(l10n.qazaRecalc),
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                            fullscreenDialog: true,
                            builder: (_) => const QazaWizard()),
                      );
                      await _reload();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Progress ring hero
              SectionCard(
                color: SukoonColors.surface,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    ProgressRing(
                      value: pct,
                      color: totalRemaining == 0
                          ? SukoonColors.lime
                          : SukoonColors.accent,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CountUpText(totalRemaining,
                              style: t.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.w700)),
                          Text(l10n.qazaOf(totalInitial),
                              style: t.labelSmall?.copyWith(
                                  color: SukoonColors.textSecondary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      totalRemaining == 0
                          ? l10n.qazaAllDone
                          : l10n.qazaRepaidPct((pct * 100).round()),
                      style: t.titleSmall?.copyWith(
                          color: totalRemaining == 0
                              ? SukoonColors.lime
                              : SukoonColors.accent),
                    ),
                    if (todayTotal > 0)
                      Text('+$todayTotal',
                          style: t.labelMedium
                              ?.copyWith(color: SukoonColors.lime)),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Per-prayer rows
              SectionCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    for (final s in _state)
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(prayerName(l10n, s.prayer),
                                  style: t.titleMedium),
                            ),
                            CountUpText(s.remaining,
                                style: t.titleMedium?.copyWith(
                                    color: s.remaining == 0
                                        ? SukoonColors.lime
                                        : SukoonColors.text)),
                            const SizedBox(width: 10),
                            _RepayButton(
                              enabled: s.remaining > 0,
                              onTap: () => _repay(s.prayer, 1),
                              onLongPress: () => _repay(s.prayer, 5),
                            ),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 6),
                      child: Text(l10n.qazaLongPressHint,
                          style: t.labelSmall
                              ?.copyWith(color: SukoonColors.textFaint)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              PlannerCard(
                remaining: _remaining,
                todayTotal: todayTotal,
                planStreakDays: _planStreak,
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: 12),

              SectionCard(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const AchievementsWall()),
                ),
                child: Row(
                  children: [
                    const Text('🏅'),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(l10n.achievementsTitle,
                            style: t.titleMedium)),
                    Text(
                        '$_unlockedCount / ${AchievementIds.all.length}',
                        style: t.labelLarge
                            ?.copyWith(color: SukoonColors.accent)),
                    const Icon(Icons.chevron_right,
                        color: SukoonColors.textFaint),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),

          // Confetti overlay (≤2s, fires only on fresh achievements)
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 24,
              maxBlastForce: 18,
              minBlastForce: 6,
              gravity: 0.25,
              shouldLoop: false,
              colors: const [
                SukoonColors.accent,
                SukoonColors.lime,
                SukoonColors.text,
                SukoonColors.warning,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RepayButton extends StatelessWidget {
  const _RepayButton({
    required this.enabled,
    required this.onTap,
    required this.onLongPress,
  });

  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? SukoonColors.accent : SukoonColors.cardRaised,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: enabled ? onTap : null,
        onLongPress: enabled ? onLongPress : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check,
                  size: 16,
                  color: enabled ? SukoonColors.bg : SukoonColors.textFaint),
              const SizedBox(width: 4),
              Text(
                '-1',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: enabled ? SukoonColors.bg : SukoonColors.textFaint,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
