import 'package:sqflite/sqflite.dart';

import 'package:sukoon/data/db.dart';

class QazaPrayerState {
  const QazaPrayerState(this.prayer, this.initialOwed, this.repaid);
  final String prayer;
  final int initialOwed;
  final int repaid;
  int get remaining => (initialOwed - repaid) < 0 ? 0 : initialOwed - repaid;
}

class RepayResult {
  const RepayResult(this.applied, this.logId);
  final int applied; // may be less than requested (capped at remaining)
  final int? logId; // null when nothing was applied
}

class QazaRepository {
  QazaRepository._();

  static Future<bool> hasLedger() async {
    final db = await AppDb.get();
    final rows = await db.query('qaza_state', limit: 1);
    return rows.isNotEmpty;
  }

  static Future<List<QazaPrayerState>> state() async {
    final db = await AppDb.get();
    final rows = await db.query('qaza_state');
    return [
      for (final r in rows)
        QazaPrayerState(
          r['prayer'] as String,
          r['initial_owed'] as int,
          r['repaid'] as int,
        )
    ];
  }

  /// Creates/overwrites the ledger from wizard output.
  /// PRESERVES repaid counts on re-runs; never resets progress.
  /// (Manual query-then-write — SQLite UPSERT needs 3.24+, minSdk 24 has 3.9.)
  static Future<void> initLedger(Map<String, int> owedPerPrayer) async {
    final db = await AppDb.get();
    await db.transaction((txn) async {
      final existing = await txn.query('qaza_state');
      final repaidBy = {
        for (final r in existing) r['prayer'] as String: r['repaid'] as int
      };
      await txn.delete('qaza_state');
      for (final e in owedPerPrayer.entries) {
        final repaid = repaidBy[e.key] ?? 0;
        await txn.insert('qaza_state', {
          'prayer': e.key,
          // Owed can never be below what was already repaid.
          'initial_owed': e.value < repaid ? repaid : e.value,
          'repaid': repaid,
        });
      }
    });
  }

  /// Applies up to [count] repayments for [prayer] on [date].
  static Future<RepayResult> repay(String prayer, int count, String date) async {
    final db = await AppDb.get();
    return db.transaction<RepayResult>((txn) async {
      final rows = await txn
          .query('qaza_state', where: 'prayer = ?', whereArgs: [prayer]);
      if (rows.isEmpty) return const RepayResult(0, null);
      final initial = rows.first['initial_owed'] as int;
      final repaid = rows.first['repaid'] as int;
      final remaining = initial - repaid;
      final applied = count > remaining ? remaining : count;
      if (applied <= 0) return const RepayResult(0, null);
      await txn.update('qaza_state', {'repaid': repaid + applied},
          where: 'prayer = ?', whereArgs: [prayer]);
      final logId = await txn.insert('qaza_log',
          {'date': date, 'prayer': prayer, 'count': applied});
      return RepayResult(applied, logId);
    });
  }

  /// Undo a repay action by its qaza_log id.
  static Future<void> undoRepay(int logId) async {
    final db = await AppDb.get();
    await db.transaction((txn) async {
      final rows =
          await txn.query('qaza_log', where: 'id = ?', whereArgs: [logId]);
      if (rows.isEmpty) return;
      final prayer = rows.first['prayer'] as String;
      final count = rows.first['count'] as int;
      await txn.delete('qaza_log', where: 'id = ?', whereArgs: [logId]);
      final st = await txn
          .query('qaza_state', where: 'prayer = ?', whereArgs: [prayer]);
      if (st.isEmpty) return;
      var repaid = (st.first['repaid'] as int) - count;
      if (repaid < 0) repaid = 0;
      await txn.update('qaza_state', {'repaid': repaid},
          where: 'prayer = ?', whereArgs: [prayer]);
    });
  }

  /// prayer → total repaid on [date].
  static Future<Map<String, int>> repaidOn(String date) async {
    final db = await AppDb.get();
    final rows = await db.rawQuery(
        'SELECT prayer, SUM(count) AS c FROM qaza_log WHERE date = ? '
        'GROUP BY prayer',
        [date]);
    return {
      for (final r in rows) r['prayer'] as String: (r['c'] as num).toInt()
    };
  }

  /// dateKey → total repaid that day, for the last [lastNDays] window
  /// starting at [fromDate] (yyyy-MM-dd, inclusive). For plan streaks.
  static Future<Map<String, int>> dailyTotalsSince(String fromDate) async {
    final db = await AppDb.get();
    final rows = await db.rawQuery(
        'SELECT date, SUM(count) AS c FROM qaza_log WHERE date >= ? '
        'GROUP BY date',
        [fromDate]);
    return {
      for (final r in rows) r['date'] as String: (r['c'] as num).toInt()
    };
  }

  // ---- tracker integration ----

  /// Tracker marked a prayer missed: +1 owed if the ledger exists,
  /// otherwise remember it for the wizard.
  static Future<void> addMissed(String date, String prayer) async {
    final db = await AppDb.get();
    await db.transaction((txn) async {
      final st = await txn
          .query('qaza_state', where: 'prayer = ?', whereArgs: [prayer]);
      if (st.isNotEmpty) {
        final initial = st.first['initial_owed'] as int;
        await txn.update('qaza_state', {'initial_owed': initial + 1},
            where: 'prayer = ?', whereArgs: [prayer]);
      } else {
        await txn.insert('pending_missed', {'date': date, 'prayer': prayer},
            conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
  }

  /// Undo of the above (status changed away from missed).
  static Future<void> removeMissed(String date, String prayer) async {
    final db = await AppDb.get();
    await db.transaction((txn) async {
      final st = await txn
          .query('qaza_state', where: 'prayer = ?', whereArgs: [prayer]);
      if (st.isNotEmpty) {
        final initial = st.first['initial_owed'] as int;
        final repaid = st.first['repaid'] as int;
        var next = initial - 1;
        if (next < repaid) next = repaid; // never below repaid
        if (next < 0) next = 0;
        await txn.update('qaza_state', {'initial_owed': next},
            where: 'prayer = ?', whereArgs: [prayer]);
      } else {
        await txn.delete('pending_missed',
            where: 'date = ? AND prayer = ?', whereArgs: [date, prayer]);
      }
    });
  }

  /// prayer → count of missed marks waiting for the wizard.
  static Future<Map<String, int>> pendingMissedByPrayer() async {
    final db = await AppDb.get();
    final rows = await db.rawQuery(
        'SELECT prayer, COUNT(*) AS c FROM pending_missed GROUP BY prayer');
    return {
      for (final r in rows) r['prayer'] as String: (r['c'] as num).toInt()
    };
  }

  /// Folds pending tracker misses into a fresh ledger, then clears them.
  static Future<void> consumePendingMissed() async {
    final db = await AppDb.get();
    await db.transaction((txn) async {
      final rows = await txn.rawQuery(
          'SELECT prayer, COUNT(*) AS c FROM pending_missed GROUP BY prayer');
      for (final r in rows) {
        final prayer = r['prayer'] as String;
        final c = (r['c'] as num).toInt();
        final st = await txn
            .query('qaza_state', where: 'prayer = ?', whereArgs: [prayer]);
        if (st.isNotEmpty) {
          final initial = st.first['initial_owed'] as int;
          await txn.update('qaza_state', {'initial_owed': initial + c},
              where: 'prayer = ?', whereArgs: [prayer]);
        }
      }
      await txn.delete('pending_missed');
    });
  }

  static Future<(int total, int repaid)> totals() async {
    final db = await AppDb.get();
    final rows = await db.rawQuery(
        'SELECT SUM(initial_owed) AS t, SUM(repaid) AS r FROM qaza_state');
    if (rows.isEmpty) return (0, 0);
    return (
      ((rows.first['t'] as num?) ?? 0).toInt(),
      ((rows.first['r'] as num?) ?? 0).toInt()
    );
  }
}
