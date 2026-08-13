import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// sukoon.db — tracker + qaza history. Nothing here ever leaves the phone.
///
/// SCHEMA CHANGES: bump [schemaVersion], write a hand-written migration in
/// [_upgrade], and add an upgrade-path test. Never edit v1 in place once
/// testers have the app installed.
class AppDb {
  AppDb._();

  static const schemaVersion = 1;
  static Database? _db;

  static Future<Database> get() async {
    _db ??= await openDatabase(
      join(await getDatabasesPath(), 'sukoon.db'),
      version: schemaVersion,
      onCreate: _create,
      onUpgrade: _upgrade,
    );
    return _db!;
  }

  /// v1 creates the full schema (fresh installs — there are no pre-v1 users).
  static Future<void> _create(Database db, int version) async {
    // Daily check-off: status = prayed | jamaat | missed.
    await db.execute('CREATE TABLE prayer_log('
        'date TEXT NOT NULL, '
        'prayer TEXT NOT NULL, '
        'status TEXT NOT NULL, '
        'PRIMARY KEY(date, prayer))');

    // Period mode days (women) — excluded from streaks and stats.
    await db.execute('CREATE TABLE period_day(date TEXT PRIMARY KEY)');

    // Qaza ledger: one row per prayer type (fajr..isha, witr).
    await db.execute('CREATE TABLE qaza_state('
        'prayer TEXT PRIMARY KEY, '
        'initial_owed INTEGER NOT NULL, '
        'repaid INTEGER NOT NULL DEFAULT 0)');

    // Every "+N repaid" action (for undo, daily totals, plan streak).
    await db.execute('CREATE TABLE qaza_log('
        'id INTEGER PRIMARY KEY AUTOINCREMENT, '
        'date TEXT NOT NULL, '
        'prayer TEXT NOT NULL, '
        'count INTEGER NOT NULL)');

    // Tracker "missed" marks made before the qaza wizard has been run.
    await db.execute('CREATE TABLE pending_missed('
        'date TEXT NOT NULL, '
        'prayer TEXT NOT NULL, '
        'PRIMARY KEY(date, prayer))');

    await db.execute('CREATE TABLE achievements('
        'id TEXT PRIMARY KEY, '
        'unlocked_at TEXT NOT NULL)');
  }

  static Future<void> _upgrade(Database db, int from, int to) async {
    // Migration pattern for future versions:
    // if (from < 2) { await db.execute('ALTER TABLE ...'); }
  }

  /// Test hook — lets tests inject an in-memory database.
  static void debugSetDatabase(Database db) => _db = db;
}
