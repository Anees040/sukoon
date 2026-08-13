import 'package:sqflite/sqflite.dart';
import 'package:sukoon/data/db.dart';

/// Tracker statuses.
class PrayerStatus {
  static const prayed = 'prayed';
  static const jamaat = 'jamaat';
  static const missed = 'missed';

  /// Check-off tap cycle: none → prayed → jamaat → missed → none.
  static String? nextInCycle(String? current) => switch (current) {
        null => prayed,
        prayed => jamaat,
        jamaat => missed,
        _ => null,
      };

  static bool countsAsDone(String? s) => s == prayed || s == jamaat;
}

class PrayerLogRepository {
  PrayerLogRepository._();

  /// Upserts a status; null deletes the row.
  static Future<void> setStatus(
      String date, String prayer, String? status) async {
    final db = await AppDb.get();
    if (status == null) {
      await db.delete('prayer_log',
          where: 'date = ? AND prayer = ?', whereArgs: [date, prayer]);
    } else {
      await db.insert(
        'prayer_log',
        {'date': date, 'prayer': prayer, 'status': status},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  /// prayer → status for one day.
  static Future<Map<String, String>> day(String date) async {
    final db = await AppDb.get();
    final rows =
        await db.query('prayer_log', where: 'date = ?', whereArgs: [date]);
    return {
      for (final r in rows) r['prayer'] as String: r['status'] as String
    };
  }

  /// date → (prayer → status) for every logged day since [fromDate]
  /// (inclusive). Used by streak math; string compare works on yyyy-MM-dd.
  static Future<Map<String, Map<String, String>>> since(String fromDate) async {
    final db = await AppDb.get();
    final rows = await db.query('prayer_log',
        where: 'date >= ?', whereArgs: [fromDate]);
    final out = <String, Map<String, String>>{};
    for (final r in rows) {
      final date = r['date'] as String;
      (out[date] ??= {})[r['prayer'] as String] = r['status'] as String;
    }
    return out;
  }

  /// date → (prayer → status) for a month. [monthPrefix] like '2026-08'.
  static Future<Map<String, Map<String, String>>> month(
      String monthPrefix) async {
    final db = await AppDb.get();
    final rows = await db.query('prayer_log',
        where: 'date LIKE ?', whereArgs: ['$monthPrefix-%']);
    final out = <String, Map<String, String>>{};
    for (final r in rows) {
      final date = r['date'] as String;
      (out[date] ??= {})[r['prayer'] as String] = r['status'] as String;
    }
    return out;
  }

  // ---- period mode ----

  static Future<void> setPeriodDay(String date, bool on) async {
    final db = await AppDb.get();
    if (on) {
      await db.insert('period_day', {'date': date},
          conflictAlgorithm: ConflictAlgorithm.ignore);
    } else {
      await db.delete('period_day', where: 'date = ?', whereArgs: [date]);
    }
  }

  static Future<bool> isPeriodDay(String date) async {
    final db = await AppDb.get();
    final rows =
        await db.query('period_day', where: 'date = ?', whereArgs: [date]);
    return rows.isNotEmpty;
  }

  static Future<Set<String>> periodDaysSince(String fromDate) async {
    final db = await AppDb.get();
    final rows = await db.query('period_day',
        where: 'date >= ?', whereArgs: [fromDate]);
    return {for (final r in rows) r['date'] as String};
  }

  static Future<Set<String>> periodDaysInMonth(String monthPrefix) async {
    final db = await AppDb.get();
    final rows = await db.query('period_day',
        where: 'date LIKE ?', whereArgs: ['$monthPrefix-%']);
    return {for (final r in rows) r['date'] as String};
  }
}
