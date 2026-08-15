import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sukoon/constants.dart';
import 'package:sukoon/core/dates.dart';
import 'package:sukoon/core/l10n_ext.dart';
import 'package:sukoon/core/prefs.dart';
import 'package:sukoon/data/prayer_log_repository.dart';
import 'package:sukoon/data/qaza_repository.dart';
import 'package:sukoon/features/common/widgets.dart';
import 'package:sukoon/features/tracker/heatmap.dart';
import 'package:sukoon/features/tracker/streak.dart';
import 'package:sukoon/l10n/gen/app_localizations.dart';
import 'package:sukoon/prayer/prayer_service.dart';
import 'package:sukoon/theme.dart';

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  DateTime _selected = DateTime.now();
  DateTime _visibleMonth = DateTime.now(); // month shown in heatmap

  Map<String, Map<String, String>> _monthLogs = {};
  Set<String> _monthPeriods = {};
  Map<String, Map<String, String>> _streakLogs = {};
  Set<String> _streakPeriods = {};
  bool _loading = true;
  String? _error;

  /// Prayers we already auto-missed this session (avoids duplicate DB writes
  /// every time _reload() is called). Keyed as "date:prayer".
  final Set<String> _autoMissedKeys = {};

  @override
  void initState() {
    super.initState();
    _reload();
  }

  String get _monthPrefix =>
      '${_visibleMonth.year.toString().padLeft(4, '0')}-${_visibleMonth.month.toString().padLeft(2, '0')}';

  Future<void> _reload() async {
    try {
      final from = dateKey(
          dateOnly(DateTime.now()).subtract(const Duration(days: 400)));
      final results = await Future.wait([
        PrayerLogRepository.month(_monthPrefix),
        PrayerLogRepository.periodDaysInMonth(_monthPrefix),
        PrayerLogRepository.since(from),
        PrayerLogRepository.periodDaysSince(from),
      ]);
      if (!mounted) return;
      setState(() {
        _monthLogs = results[0] as Map<String, Map<String, String>>;
        _monthPeriods = results[1] as Set<String>;
        _streakLogs = results[2] as Map<String, Map<String, String>>;
        _streakPeriods = results[3] as Set<String>;
        _loading = false;
        _error = null;
      });
      // After data loads, auto-detect unmarked prayers as missed.
      await _autoDetectMissed();
    } catch (e, st) {
      // A DB error must never leave the screen spinning forever. Surface it
      // so it can be diagnosed (e.g. a stale schema needing app-data clear).
      debugPrint('Tracker load failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  /// Check today's and yesterday's prayers: if a prayer's time has passed
  /// and it is still unmarked (null status), auto-add it to the qaza ledger.
  /// When Isha is auto-missed, Witr is also auto-missed (if enabled).
  /// The entry stays until the user manually marks it prayed/jamaat.
  Future<void> _autoDetectMissed() async {
    final now = DateTime.now();
    final today = dateOnly(now);
    // Check today and yesterday (to catch last night's Isha/Witr).
    for (final day in [today, previousDay(today)]) {
      final key = dateKey(day);
      // Skip period days — prayers are excused.
      if (_monthPeriods.contains(key)) continue;

      final dayTimes = PrayerService.forDay(
        day: day,
        lat: Prefs.lat,
        lng: Prefs.lng,
        method: Prefs.method,
        madhab: Prefs.madhab,
      ).toMap();

      final dayLog = _monthLogs[key] ?? {};

      for (final prayer in PrayerKeys.five) {
        final prayerTime = dayTimes[prayer]!;
        // Only consider prayers whose time has already passed.
        if (!prayerTime.isBefore(now)) continue;
        // Only auto-miss if the user hasn't marked it at all (null).
        if (dayLog[prayer] != null) continue;
        final autoKey = '$key:$prayer';
        if (_autoMissedKeys.contains(autoKey)) continue;

        _autoMissedKeys.add(autoKey);
        await QazaRepository.addMissed(key, prayer);

        // Isha missed → Witr also missed (Hanafi default).
        if (prayer == PrayerKeys.isha && Prefs.witrEnabled) {
          final witrKey = '$key:${PrayerKeys.witr}';
          if (!_autoMissedKeys.contains(witrKey) &&
              dayLog[PrayerKeys.witr] == null) {
            _autoMissedKeys.add(witrKey);
            await QazaRepository.addMissed(key, PrayerKeys.witr);
          }
        }
      }
    }
  }

  Future<void> _cycle(String prayer) async {
    final l10n = AppLocalizations.of(context);
    final key = dateKey(_selected);
    final current = _monthLogs[key]?[prayer];
    final next = PrayerStatus.nextInCycle(current);

    HapticFeedback.selectionClick();
    await PrayerLogRepository.setStatus(key, prayer, next);

    // Keep the qaza ledger in sync with prayer marks.
    if (next == PrayerStatus.missed) {
      // Explicitly marked missed — add to qaza.
      await QazaRepository.addMissed(key, prayer);
      // Isha missed → Witr also missed.
      if (prayer == PrayerKeys.isha && Prefs.witrEnabled) {
        await QazaRepository.addMissed(key, PrayerKeys.witr);
      }
    } else if (current == PrayerStatus.missed) {
      // Was missed, now changed away from missed — remove from qaza.
      await QazaRepository.removeMissed(key, prayer);
      if (prayer == PrayerKeys.isha && Prefs.witrEnabled) {
        await QazaRepository.removeMissed(key, PrayerKeys.witr);
      }
    } else if (current == null &&
        (next == PrayerStatus.prayed || next == PrayerStatus.jamaat)) {
      // Was unmarked (possibly auto-missed) → now prayed/jamaat.
      // Remove the auto-missed entry.
      await QazaRepository.removeMissed(key, prayer);
      _autoMissedKeys.remove('$key:$prayer');
      if (prayer == PrayerKeys.isha && Prefs.witrEnabled) {
        await QazaRepository.removeMissed(key, PrayerKeys.witr);
        _autoMissedKeys.remove('$key:${PrayerKeys.witr}');
      }
    }
    await _reload();

    if (next == PrayerStatus.missed && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(l10n.trackerMissedAdded(prayerName(l10n, prayer))),
          action: SnackBarAction(
            label: l10n.undo,
            onPressed: () async {
              await PrayerLogRepository.setStatus(key, prayer, current);
              await QazaRepository.removeMissed(key, prayer);
              if (prayer == PrayerKeys.isha && Prefs.witrEnabled) {
                await QazaRepository.removeMissed(key, PrayerKeys.witr);
              }
              await _reload();
            },
          ),
        ));
    }
  }

  Future<void> _togglePeriod() async {
    final key = dateKey(_selected);
    final on = _monthPeriods.contains(key);
    await PrayerLogRepository.setPeriodDay(key, !on);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;

    if (_loading) {
      return const SafeArea(
          child: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return SafeArea(
        child: _TrackerError(
          message: l10n.trackerLoadError,
          detail: _error!,
          retryLabel: l10n.retry,
          onRetry: () {
            setState(() {
              _loading = true;
              _error = null;
            });
            _reload();
          },
        ),
      );
    }

    final today = dateOnly(DateTime.now());
    final selKey = dateKey(_selected);
    final isPeriodDay = _monthPeriods.contains(selKey);

    final streak = currentStreak(
        logsByDate: _streakLogs, periodDays: _streakPeriods, today: today);
    final best = bestStreak(
        logsByDate: _streakLogs, periodDays: _streakPeriods, today: today);
    final stats = monthStats(
      monthLogs: _monthLogs,
      periodDays: _monthPeriods,
      year: _visibleMonth.year,
      month: _visibleMonth.month,
      today: today,
    );

    final dayTimes = PrayerService.forDay(
      day: _selected,
      lat: Prefs.lat,
      lng: Prefs.lng,
      method: Prefs.method,
      madhab: Prefs.madhab,
    ).toMap();

    final doneCount = <String, int>{
      for (final e in _monthLogs.entries)
        e.key: e.value.values
            .where((s) => s == PrayerStatus.prayed || s == PrayerStatus.jamaat)
            .length,
    };

    return SafeArea(
      child: ListView(
        padding: kScreenPad,
        children: [
          Text(l10n.tabTracker, style: t.titleLarge),
          const SizedBox(height: 12),

          // Streak header
          Row(
            children: [
              Expanded(
                child: SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.local_fire_department,
                            size: 16, color: SukoonColors.accent),
                        const SizedBox(width: 6),
                        Text(l10n.trackerStreakLabel,
                            style: t.labelMedium?.copyWith(
                                color: SukoonColors.textSecondary)),
                      ]),
                      const SizedBox(height: 4),
                      CountUpText(streak,
                          style: t.headlineMedium
                              ?.copyWith(color: SukoonColors.accent)),
                      Text(l10n.trackerDays(streak),
                          style: t.labelSmall?.copyWith(
                              color: SukoonColors.textFaint)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.trackerBestLabel,
                          style: t.labelMedium?.copyWith(
                              color: SukoonColors.textSecondary)),
                      const SizedBox(height: 4),
                      CountUpText(best,
                          style: t.headlineMedium
                              ?.copyWith(color: SukoonColors.lime)),
                      Text(
                          l10n.trackerCompletion(
                              stats.completionPct.round()),
                          style: t.labelSmall?.copyWith(
                              color: SukoonColors.textFaint)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Selected day check-off card
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                          formatShortDate(l10n.localeName, _selected),
                          style: t.titleMedium),
                    ),
                    FilterChip(
                      label: Text(l10n.trackerPeriodDay),
                      selected: isPeriodDay,
                      onSelected: (_) => _togglePeriod(),
                    ),
                  ],
                ),
                if (isPeriodDay)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(l10n.trackerPeriodHint,
                        style: t.bodySmall?.copyWith(
                            color: SukoonColors.textSecondary)),
                  )
                else ...[
                  const SizedBox(height: 6),
                  for (final prayer in PrayerKeys.five)
                    _PrayerRow(
                      prayer: prayer,
                      time: dayTimes[prayer]!,
                      status: _monthLogs[selKey]?[prayer],
                      locked: dateKey(_selected) == dateKey(today) &&
                          dayTimes[prayer]!.isAfter(DateTime.now()),
                      onTap: () => _cycle(prayer),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Month heatmap + nav
          SectionCard(
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        setState(() {
                          _visibleMonth = DateTime(_visibleMonth.year,
                              _visibleMonth.month - 1, 1);
                          _loading = true;
                        });
                        _reload();
                      },
                    ),
                    Expanded(
                      child: Text(
                        '${_visibleMonth.year}-${_visibleMonth.month.toString().padLeft(2, '0')}',
                        textAlign: TextAlign.center,
                        style: t.titleSmall,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _visibleMonth.year == today.year &&
                              _visibleMonth.month == today.month
                          ? null
                          : () {
                              setState(() {
                                _visibleMonth = DateTime(
                                    _visibleMonth.year,
                                    _visibleMonth.month + 1,
                                    1);
                                _loading = true;
                              });
                              _reload();
                            },
                    ),
                  ],
                ),
                MonthHeatmap(
                  year: _visibleMonth.year,
                  month: _visibleMonth.month,
                  doneCountByDate: doneCount,
                  periodDays: _monthPeriods,
                  today: today,
                  selected: _selected,
                  onTapDay: (d) => setState(() => _selected = d),
                ),
                const SizedBox(height: 8),
                Text(l10n.heatmapHint,
                    style: t.labelSmall
                        ?.copyWith(color: SukoonColors.textFaint)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Month stats
          Row(
            children: [
              _StatPill(
                  label: l10n.statusPrayed,
                  value: stats.prayedCount - stats.jamaatCount,
                  color: SukoonColors.accent),
              const SizedBox(width: 8),
              _StatPill(
                  label: l10n.statusJamaat,
                  value: stats.jamaatCount,
                  color: SukoonColors.lime),
              const SizedBox(width: 8),
              _StatPill(
                  label: l10n.statusMissed,
                  value: stats.missedCount,
                  color: SukoonColors.danger),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _PrayerRow extends StatelessWidget {
  const _PrayerRow({
    required this.prayer,
    required this.time,
    required this.status,
    required this.locked,
    required this.onTap,
  });

  final String prayer;
  final DateTime time;
  final String? status;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;

    final (icon, color, label) = switch (status) {
      PrayerStatus.prayed => (
          Icons.check_circle,
          SukoonColors.accent,
          l10n.statusPrayed
        ),
      PrayerStatus.jamaat => (
          Icons.groups,
          SukoonColors.lime,
          l10n.statusJamaat
        ),
      PrayerStatus.missed => (
          Icons.cancel,
          SukoonColors.danger,
          l10n.statusMissed
        ),
      _ => (
          Icons.radio_button_unchecked,
          SukoonColors.textFaint,
          l10n.statusNone
        ),
    };

    return InkWell(
      onTap: locked ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 76,
              child: Text(formatTime(l10n.localeName, time),
                  style: t.bodySmall
                      ?.copyWith(color: SukoonColors.textSecondary)),
            ),
            Expanded(
              child: Text(prayerName(l10n, prayer),
                  style: t.titleMedium?.copyWith(
                      color:
                          locked ? SukoonColors.textFaint : SukoonColors.text)),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, anim) => ScaleTransition(
                scale:
                    CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                child: child,
              ),
              child: Row(
                key: ValueKey(status),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style: t.labelMedium?.copyWith(
                          color: locked ? SukoonColors.textFaint : color)),
                  const SizedBox(width: 6),
                  Icon(icon,
                      color: locked ? SukoonColors.textFaint : color,
                      size: 22),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill(
      {required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: SukoonColors.card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text('$value',
                style: t.titleMedium?.copyWith(
                    color: color, fontWeight: FontWeight.w700)),
            Text(label,
                style:
                    t.labelSmall?.copyWith(color: SukoonColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

/// Shown when the tracker's database load fails, instead of an endless spinner.
/// Keeps the raw error visible (dimmed) so it can be reported/diagnosed.
class _TrackerError extends StatelessWidget {
  const _TrackerError({
    required this.message,
    required this.detail,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String detail;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: kScreenPad,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 40, color: SukoonColors.danger),
            const SizedBox(height: 12),
            Text(message, style: t.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(detail,
                style: t.bodySmall?.copyWith(color: SukoonColors.textFaint),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: Text(retryLabel)),
          ],
        ),
      ),
    );
  }
}
