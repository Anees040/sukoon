import 'dart:math' as math;

import 'package:sukoon/core/dates.dart';

/// Pure plan math — no Flutter imports, fully unit-testable.
///
/// A "set" = one qaza of each prayer type that is still owed.
/// If someone owes 100 of each of 6 types and repays 2 sets/day,
/// they finish in ceil(100 / 2) = 50 days.

int maxRemaining(Map<String, int> remainingPerPrayer) {
  var maxV = 0;
  for (final v in remainingPerPrayer.values) {
    if (v > maxV) maxV = v;
  }
  return maxV;
}

/// Days needed to clear the largest per-prayer balance at [dailySets]
/// sets per day. Returns 0 when nothing is owed.
int projectedFinishDays({
  required Map<String, int> remainingPerPrayer,
  required int dailySets,
}) {
  final target = maxRemaining(remainingPerPrayer);
  if (target <= 0 || dailySets <= 0) return 0;
  return (target / dailySets).ceil();
}

/// Honest daily time cost: sets × owed prayer types × minutes per qaza.
int estimatedMinutesPerDay({
  required int dailySets,
  required int owedTypes,
  required int minutesPerQaza,
}) {
  return math.max(0, dailySets * owedTypes * minutesPerQaza);
}

/// Consecutive days (ending today, or yesterday if today's target isn't
/// met yet) where the user repaid at least [requiredPerDay] prayers.
/// [dailyTotals] maps dateKey (yyyy-MM-dd) → total repaid that day.
int planStreak({
  required Map<String, int> dailyTotals,
  required int requiredPerDay,
  required DateTime today,
}) {
  if (requiredPerDay <= 0) return 0;
  var day = dateOnly(today);

  // Today is optional — an unfinished today must not break the streak.
  if ((dailyTotals[dateKey(day)] ?? 0) < requiredPerDay) {
    day = previousDay(day);
  }

  var streak = 0;
  while ((dailyTotals[dateKey(day)] ?? 0) >= requiredPerDay) {
    streak++;
    day = previousDay(day);
  }
  return streak;
}
