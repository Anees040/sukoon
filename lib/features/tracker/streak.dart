import 'package:sukoon/core/dates.dart';
import 'package:sukoon/data/prayer_log_repository.dart';

/// Pure streak & month-stats math — unit-tested in test/streak_test.dart.
///
/// Rules (documented for the explainer & tests):
/// - A day is COMPLETE when all 5 prayers are prayed or in jama'at.
/// - Excused (period) days count as complete — they never break a streak.
///   "Your streak stays safe."
/// - Today is optional: an unfinished today doesn't break the streak,
///   but a finished today extends it.

bool _isComplete(
  Map<String, Map<String, String>> logsByDate,
  Set<String> periodDays,
  DateTime day,
) {
  final key = dateKey(day);
  if (periodDays.contains(key)) return true;
  final statuses = logsByDate[key];
  if (statuses == null) return false;
  var done = 0;
  for (final s in statuses.values) {
    if (PrayerStatus.countsAsDone(s)) done++;
  }
  return done >= 5;
}

/// Consecutive complete days ending today (or yesterday when today is
/// still in progress).
int currentStreak({
  required Map<String, Map<String, String>> logsByDate,
  required Set<String> periodDays,
  required DateTime today,
}) {
  var day = dateOnly(today);
  if (!_isComplete(logsByDate, periodDays, day)) {
    day = previousDay(day);
  }
  var streak = 0;
  while (_isComplete(logsByDate, periodDays, day)) {
    streak++;
    day = previousDay(day);
  }
  return streak;
}

/// Longest run of consecutive complete days in the loaded window.
int bestStreak({
  required Map<String, Map<String, String>> logsByDate,
  required Set<String> periodDays,
  required DateTime today,
}) {
  final todayOnly = dateOnly(today);
  final candidates = <DateTime>{};
  for (final k in {...logsByDate.keys, ...periodDays}) {
    final parts = k.split('-');
    if (parts.length != 3) continue;
    final d = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    if (!d.isAfter(todayOnly)) candidates.add(d);
  }
  final complete = [
    for (final d in candidates)
      if (_isComplete(logsByDate, periodDays, d)) d,
  ]..sort();

  var best = 0;
  var run = 0;
  DateTime? prev;
  for (final d in complete) {
    if (prev != null && d.difference(prev).inDays == 1) {
      run++;
    } else {
      run = 1;
    }
    if (run > best) best = run;
    prev = d;
  }
  return best;
}

class MonthStats {
  const MonthStats({
    required this.prayedCount,
    required this.jamaatCount,
    required this.missedCount,
    required this.completionPct,
  });

  /// All prayers done (prayed + jama'at).
  final int prayedCount;

  /// Jama'at subset.
  final int jamaatCount;

  final int missedCount;

  /// Complete days ÷ counted days × 100. Counted days = days elapsed so
  /// far this month (full month for past months) minus excused days.
  final double completionPct;
}

MonthStats monthStats({
  required Map<String, Map<String, String>> monthLogs,
  required Set<String> periodDays,
  required int year,
  required int month,
  required DateTime today,
}) {
  final daysInMonth = DateTime(year, month + 1, 0).day;
  final todayOnly = dateOnly(today);

  var counted = 0;
  var completeDays = 0;
  var prayed = 0;
  var jamaat = 0;
  var missed = 0;

  for (var d = 1; d <= daysInMonth; d++) {
    final day = DateTime(year, month, d);
    if (day.isAfter(todayOnly)) break;
    final key = dateKey(day);
    final isPeriod = periodDays.contains(key);

    final statuses = monthLogs[key];
    if (statuses != null && !isPeriod) {
      for (final s in statuses.values) {
        if (PrayerStatus.countsAsDone(s)) prayed++;
        if (s == PrayerStatus.jamaat) jamaat++;
        if (s == PrayerStatus.missed) missed++;
      }
    }

    if (isPeriod) continue; // excused — out of the denominator
    counted++;
    if (_isComplete(monthLogs, periodDays, day)) completeDays++;
  }

  return MonthStats(
    prayedCount: prayed,
    jamaatCount: jamaat,
    missedCount: missed,
    completionPct: counted == 0 ? 0 : completeDays * 100.0 / counted,
  );
}
