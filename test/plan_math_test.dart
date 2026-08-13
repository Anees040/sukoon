import 'package:flutter_test/flutter_test.dart';
import 'package:sukoon/core/dates.dart';
import 'package:sukoon/qaza/plan_math.dart';

void main() {
  group('maxRemaining', () {
    test('largest per-prayer balance drives the plan', () {
      expect(
        maxRemaining({'fajr': 10, 'zuhr': 913, 'asr': 500}),
        913,
      );
    });

    test('empty ledger → 0', () {
      expect(maxRemaining({}), 0);
    });
  });

  group('projectedFinishDays', () {
    test('913 remaining at 5 sets/day → 183 days', () {
      expect(
        projectedFinishDays(
          remainingPerPrayer: {'fajr': 913},
          dailySets: 5,
        ),
        183,
      );
    });

    test('913 remaining at 10 sets/day → 92 days', () {
      expect(
        projectedFinishDays(
          remainingPerPrayer: {'fajr': 913},
          dailySets: 10,
        ),
        92,
      );
    });

    test('nothing owed or zero rate → 0', () {
      expect(
        projectedFinishDays(remainingPerPrayer: {}, dailySets: 5),
        0,
      );
      expect(
        projectedFinishDays(
          remainingPerPrayer: {'fajr': 10},
          dailySets: 0,
        ),
        0,
      );
    });
  });

  group('estimatedMinutesPerDay', () {
    test('5 sets × 6 types × 5 min → 150 min', () {
      expect(
        estimatedMinutesPerDay(
          dailySets: 5,
          owedTypes: 6,
          minutesPerQaza: 5,
        ),
        150,
      );
    });

    test('never negative', () {
      expect(
        estimatedMinutesPerDay(
          dailySets: 0,
          owedTypes: 6,
          minutesPerQaza: 5,
        ),
        0,
      );
    });
  });

  group('planStreak', () {
    final today = DateTime(2026, 8, 11);

    test('unfinished today is optional, met days count back', () {
      final totals = {
        dateKey(DateTime(2026, 8, 8)): 5,
        dateKey(DateTime(2026, 8, 9)): 6,
        dateKey(DateTime(2026, 8, 10)): 7,
        dateKey(DateTime(2026, 8, 11)): 2, // in progress
      };
      expect(
        planStreak(dailyTotals: totals, requiredPerDay: 5, today: today),
        3,
      );
    });

    test('a finished today extends the streak', () {
      final totals = {
        dateKey(DateTime(2026, 8, 9)): 5,
        dateKey(DateTime(2026, 8, 10)): 5,
        dateKey(DateTime(2026, 8, 11)): 5,
      };
      expect(
        planStreak(dailyTotals: totals, requiredPerDay: 5, today: today),
        3,
      );
    });

    test('an under-target past day breaks the streak', () {
      final totals = {
        dateKey(DateTime(2026, 8, 8)): 5,
        dateKey(DateTime(2026, 8, 9)): 4, // broke the plan here
        dateKey(DateTime(2026, 8, 10)): 5,
        dateKey(DateTime(2026, 8, 11)): 5,
      };
      expect(
        planStreak(dailyTotals: totals, requiredPerDay: 5, today: today),
        2,
      );
    });

    test('requiredPerDay 0 → no streak (guard)', () {
      expect(
        planStreak(dailyTotals: {}, requiredPerDay: 0, today: today),
        0,
      );
    });
  });
}
