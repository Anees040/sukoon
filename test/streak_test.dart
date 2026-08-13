import 'package:flutter_test/flutter_test.dart';
import 'package:sukoon/constants.dart';
import 'package:sukoon/core/dates.dart';
import 'package:sukoon/data/prayer_log_repository.dart';
import 'package:sukoon/features/tracker/streak.dart';

/// All 5 prayers done; first [jamaat] of them in jama'at.
Map<String, String> allPrayed({int jamaat = 0}) {
  final m = <String, String>{};
  for (var i = 0; i < PrayerKeys.five.length; i++) {
    m[PrayerKeys.five[i]] =
        i < jamaat ? PrayerStatus.jamaat : PrayerStatus.prayed;
  }
  return m;
}

void main() {
  final today = DateTime(2026, 8, 11);

  group('currentStreak', () {
    test('counts consecutive complete days ending today', () {
      final logs = {
        dateKey(DateTime(2026, 8, 9)): allPrayed(),
        dateKey(DateTime(2026, 8, 10)): allPrayed(),
        dateKey(DateTime(2026, 8, 11)): allPrayed(),
      };
      expect(
        currentStreak(logsByDate: logs, periodDays: {}, today: today),
        3,
      );
    });

    test('an unfinished today does not break the streak', () {
      final logs = {
        dateKey(DateTime(2026, 8, 9)): allPrayed(),
        dateKey(DateTime(2026, 8, 10)): allPrayed(),
        // today: nothing logged yet
      };
      expect(
        currentStreak(logsByDate: logs, periodDays: {}, today: today),
        2,
      );
    });

    test('period (excused) days bridge the streak — streak stays safe', () {
      final logs = {
        dateKey(DateTime(2026, 8, 8)): allPrayed(),
        dateKey(DateTime(2026, 8, 9)): allPrayed(),
        dateKey(DateTime(2026, 8, 11)): allPrayed(),
      };
      final period = {dateKey(DateTime(2026, 8, 10))};
      expect(
        currentStreak(logsByDate: logs, periodDays: period, today: today),
        4,
      );
    });

    test('a missing day breaks the streak', () {
      final logs = {
        dateKey(DateTime(2026, 8, 7)): allPrayed(),
        dateKey(DateTime(2026, 8, 8)): allPrayed(),
        // 9th missing
        dateKey(DateTime(2026, 8, 10)): allPrayed(),
        dateKey(DateTime(2026, 8, 11)): allPrayed(),
      };
      expect(
        currentStreak(logsByDate: logs, periodDays: {}, today: today),
        2,
      );
    });

    test('4 prayed + 1 missed is not a complete day', () {
      final partial = allPrayed()..[PrayerKeys.isha] = PrayerStatus.missed;
      final logs = {dateKey(DateTime(2026, 8, 11)): partial};
      expect(
        currentStreak(logsByDate: logs, periodDays: {}, today: today),
        0,
      );
    });
  });

  group('bestStreak', () {
    test('finds the longest historical run and ignores future days', () {
      final logs = {
        // run of 3
        dateKey(DateTime(2026, 8, 1)): allPrayed(),
        dateKey(DateTime(2026, 8, 2)): allPrayed(),
        dateKey(DateTime(2026, 8, 3)): allPrayed(),
        // run of 4
        dateKey(DateTime(2026, 8, 5)): allPrayed(),
        dateKey(DateTime(2026, 8, 6)): allPrayed(),
        dateKey(DateTime(2026, 8, 7)): allPrayed(),
        dateKey(DateTime(2026, 8, 8)): allPrayed(),
        // future — must be ignored
        dateKey(DateTime(2026, 8, 12)): allPrayed(),
      };
      expect(
        bestStreak(logsByDate: logs, periodDays: {}, today: today),
        4,
      );
    });

    test('period days join runs together', () {
      final logs = {
        dateKey(DateTime(2026, 8, 1)): allPrayed(),
        dateKey(DateTime(2026, 8, 2)): allPrayed(),
        dateKey(DateTime(2026, 8, 4)): allPrayed(),
        dateKey(DateTime(2026, 8, 5)): allPrayed(),
      };
      final period = {dateKey(DateTime(2026, 8, 3))};
      expect(
        bestStreak(logsByDate: logs, periodDays: period, today: today),
        5,
      );
    });
  });

  group('monthStats', () {
    test('counts, jamaat subset, and pct exclude excused days', () {
      final logs = <String, Map<String, String>>{
        // days 1–5 complete; day 3 has 2 jama'at prayers
        dateKey(DateTime(2026, 1, 1)): allPrayed(),
        dateKey(DateTime(2026, 1, 2)): allPrayed(),
        dateKey(DateTime(2026, 1, 3)): allPrayed(jamaat: 2),
        dateKey(DateTime(2026, 1, 4)): allPrayed(),
        dateKey(DateTime(2026, 1, 5)): allPrayed(),
        // day 6 is excused — any stray logs must NOT count
        dateKey(DateTime(2026, 1, 6)): {
          PrayerKeys.fajr: PrayerStatus.prayed,
          PrayerKeys.zuhr: PrayerStatus.prayed,
        },
        // day 10 (today): partial — 1 prayed, 1 missed
        dateKey(DateTime(2026, 1, 10)): {
          PrayerKeys.fajr: PrayerStatus.prayed,
          PrayerKeys.zuhr: PrayerStatus.missed,
        },
      };
      final stats = monthStats(
        monthLogs: logs,
        periodDays: {dateKey(DateTime(2026, 1, 6))},
        year: 2026,
        month: 1,
        today: DateTime(2026, 1, 10),
      );
      expect(stats.prayedCount, 26); // 5×5 + day-10 fajr
      expect(stats.jamaatCount, 2);
      expect(stats.missedCount, 1);
      // 5 complete days of 9 counted (10 elapsed − 1 excused)
      expect(stats.completionPct, closeTo(55.556, 0.01));
    });

    test('empty month → zero pct without dividing by zero', () {
      final stats = monthStats(
        monthLogs: {},
        periodDays: {},
        year: 2026,
        month: 1,
        today: DateTime(2025, 12, 31), // month not started yet
      );
      expect(stats.completionPct, 0);
      expect(stats.prayedCount, 0);
    });
  });
}
