import 'package:sukoon/data/db.dart';

/// Achievement ids. Icons/labels resolve in the UI layer
/// (features/qaza/achievements_wall.dart) and l10n.
class AchievementIds {
  static const firstQaza = 'first_qaza';
  static const planStreak7 = 'plan_streak_7';
  static const planStreak30 = 'plan_streak_30';
  static const planStreak100 = 'plan_streak_100';
  static const total100 = 'total_100';
  static const total500 = 'total_500';
  static const total1000 = 'total_1000';
  static const total5000 = 'total_5000';
  static const pct10 = 'pct_10';
  static const pct25 = 'pct_25';
  static const pct50 = 'pct_50';
  static const pct75 = 'pct_75';
  static const pct100 = 'pct_100';

  static const all = [
    firstQaza,
    planStreak7, planStreak30, planStreak100,
    total100, total500, total1000, total5000,
    pct10, pct25, pct50, pct75, pct100,
  ];
}

class AchievementsRepository {
  AchievementsRepository._();

  static Future<Set<String>> unlocked() async {
    final db = await AppDb.get();
    final rows = await db.query('achievements');
    return {for (final r in rows) r['id'] as String};
  }

  /// Checks every trigger; unlocks what newly qualifies; returns ONLY the
  /// newly unlocked ids (each fires exactly once — confetti relies on this).
  static Future<List<String>> evaluateAndUnlock({
    required int totalRepaid,
    required int totalInitial,
    required int planStreakDays,
  }) async {
    final satisfied = <String>{
      if (totalRepaid >= 1) AchievementIds.firstQaza,
      if (planStreakDays >= 7) AchievementIds.planStreak7,
      if (planStreakDays >= 30) AchievementIds.planStreak30,
      if (planStreakDays >= 100) AchievementIds.planStreak100,
      if (totalRepaid >= 100) AchievementIds.total100,
      if (totalRepaid >= 500) AchievementIds.total500,
      if (totalRepaid >= 1000) AchievementIds.total1000,
      if (totalRepaid >= 5000) AchievementIds.total5000,
    };
    if (totalInitial > 0) {
      final pct = totalRepaid * 100 / totalInitial;
      if (pct >= 10) satisfied.add(AchievementIds.pct10);
      if (pct >= 25) satisfied.add(AchievementIds.pct25);
      if (pct >= 50) satisfied.add(AchievementIds.pct50);
      if (pct >= 75) satisfied.add(AchievementIds.pct75);
      if (pct >= 100) satisfied.add(AchievementIds.pct100);
    }

    final db = await AppDb.get();
    final already = await unlocked();
    final fresh = satisfied.difference(already).toList()..sort();
    final now = DateTime.now().toIso8601String();
    for (final id in fresh) {
      await db.insert('achievements', {'id': id, 'unlocked_at': now});
    }
    return fresh;
  }
}
