import 'package:flutter/material.dart';

import 'package:sukoon/data/achievements.dart';
import 'package:sukoon/features/common/widgets.dart';
import 'package:sukoon/l10n/gen/app_localizations.dart';
import 'package:sukoon/theme.dart';

/// Localized title for an achievement id.
String achievementTitle(AppLocalizations l10n, String id) => switch (id) {
      AchievementIds.firstQaza => l10n.achFirstQaza,
      AchievementIds.planStreak7 => l10n.achStreak7,
      AchievementIds.planStreak30 => l10n.achStreak30,
      AchievementIds.planStreak100 => l10n.achStreak100,
      AchievementIds.total100 => l10n.achTotal100,
      AchievementIds.total500 => l10n.achTotal500,
      AchievementIds.total1000 => l10n.achTotal1000,
      AchievementIds.total5000 => l10n.achTotal5000,
      AchievementIds.pct10 => l10n.achPct10,
      AchievementIds.pct25 => l10n.achPct25,
      AchievementIds.pct50 => l10n.achPct50,
      AchievementIds.pct75 => l10n.achPct75,
      AchievementIds.pct100 => l10n.achPct100,
      _ => id,
    };

/// Icon per achievement — drawn Material icons, no emoji (v0.1 rule:
/// emoji render inconsistently across OEM fonts and look unpolished).
IconData achievementIcon(String id) => switch (id) {
      AchievementIds.firstQaza => Icons.spa_outlined,
      AchievementIds.planStreak7 => Icons.local_fire_department,
      AchievementIds.planStreak30 => Icons.auto_awesome,
      AchievementIds.planStreak100 => Icons.emoji_events,
      AchievementIds.total100 => Icons.star_border,
      AchievementIds.total500 => Icons.star_half,
      AchievementIds.total1000 => Icons.star,
      AchievementIds.total5000 => Icons.workspace_premium,
      AchievementIds.pct10 => Icons.flag_outlined,
      AchievementIds.pct25 => Icons.trending_up,
      AchievementIds.pct50 => Icons.donut_large,
      AchievementIds.pct75 => Icons.diamond_outlined,
      AchievementIds.pct100 => Icons.celebration,
      _ => Icons.military_tech,
    };

class AchievementsWall extends StatefulWidget {
  const AchievementsWall({super.key});

  @override
  State<AchievementsWall> createState() => _AchievementsWallState();
}

class _AchievementsWallState extends State<AchievementsWall> {
  Set<String> _unlocked = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    AchievementsRepository.unlocked().then((u) {
      if (mounted) {
        setState(() {
          _unlocked = u;
          _loading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.achievementsTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: kScreenPad,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.4,
              ),
              itemCount: AchievementIds.all.length,
              itemBuilder: (context, i) {
                final id = AchievementIds.all[i];
                final unlocked = _unlocked.contains(id);
                return SectionCard(
                  color: unlocked
                      ? SukoonColors.accentDim
                      : SukoonColors.card,
                  borderColor:
                      unlocked ? SukoonColors.accent : SukoonColors.stroke,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Opacity(
                        opacity: unlocked ? 1 : 0.35,
                        child: Icon(
                          achievementIcon(id),
                          size: 30,
                          color: unlocked
                              ? SukoonColors.accent
                              : SukoonColors.textFaint,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        achievementTitle(l10n, id),
                        textAlign: TextAlign.center,
                        style: t.labelLarge?.copyWith(
                          color: unlocked
                              ? SukoonColors.text
                              : SukoonColors.textFaint,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
