import 'package:flutter/material.dart';

import 'package:sukoon/core/l10n_ext.dart';
import 'package:sukoon/core/prefs.dart';
import 'package:sukoon/features/common/widgets.dart';
import 'package:sukoon/l10n/gen/app_localizations.dart';
import 'package:sukoon/qaza/plan_math.dart';
import 'package:sukoon/theme.dart';

/// Daily repayment plan card: target sets/day, honest time cost,
/// projected finish date, today's progress and plan streak.
class PlannerCard extends StatelessWidget {
  const PlannerCard({
    super.key,
    required this.remaining,
    required this.todayTotal,
    required this.planStreakDays,
    required this.onChanged,
  });

  /// prayer → remaining count (only rows with remaining > 0 matter).
  final Map<String, int> remaining;
  final int todayTotal;
  final int planStreakDays;
  final VoidCallback onChanged;

  int get _owedTypes {
    final n = remaining.values.where((v) => v > 0).length;
    return n == 0 ? 1 : n;
  }

  Future<void> _setTarget(BuildContext context, int? preset) async {
    if (preset != null) {
      await Prefs.setDailyTargetSets(preset);
      onChanged();
      return;
    }
    final l10n = AppLocalizations.of(context);
    final controller =
        TextEditingController(text: '${Prefs.dailyTargetSets}');
    final v = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.planCustom),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () {
              final n = int.tryParse(controller.text.trim());
              Navigator.pop(context, n?.clamp(1, 50));
            },
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
    if (v != null) {
      await Prefs.setDailyTargetSets(v);
      onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final target = Prefs.dailyTargetSets;
    final owedTypes = _owedTypes;

    final days = projectedFinishDays(
        remainingPerPrayer: remaining, dailySets: target);
    final minutes = estimatedMinutesPerDay(
      dailySets: target,
      owedTypes: owedTypes,
      minutesPerQaza: Prefs.minutesPerQaza,
    );
    final requiredToday = target * owedTypes;
    final finishDate = days <= 0
        ? null
        : DateTime.now().add(Duration(days: days));

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.planTitle, style: t.titleMedium),
          const SizedBox(height: 4),
          Text(l10n.planSetsHint,
              style:
                  t.bodySmall?.copyWith(color: SukoonColors.textSecondary)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in const [1, 2, 5, 10])
                ChoiceChip(
                  label: Text('$preset'),
                  selected: target == preset,
                  onSelected: (_) => _setTarget(context, preset),
                ),
              ChoiceChip(
                label: Text(const [1, 2, 5, 10].contains(target)
                    ? l10n.planCustom
                    : '${l10n.planCustom}: $target'),
                selected: !const [1, 2, 5, 10].contains(target),
                onSelected: (_) => _setTarget(context, null),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (days > 0 && finishDate != null) ...[
            Row(
              children: [
                const Icon(Icons.flag_outlined,
                    size: 18, color: SukoonColors.lime),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${l10n.planFinishIn(days)} · ${l10n.planFinishDate(formatDateWithYear(l10n.localeName, finishDate))}',
                    style: t.bodyLarge?.copyWith(color: SukoonColors.lime),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          Row(
            children: [
              const Icon(Icons.schedule,
                  size: 18, color: SukoonColors.textSecondary),
              const SizedBox(width: 8),
              Text(l10n.planMinutes(minutes),
                  style: t.bodyMedium
                      ?.copyWith(color: SukoonColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 10),
          // today's progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: requiredToday == 0
                  ? 0
                  : (todayTotal / requiredToday).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: SukoonColors.cardRaised,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                    l10n.planTodayProgress(todayTotal, requiredToday),
                    style: t.labelMedium
                        ?.copyWith(color: SukoonColors.textSecondary)),
              ),
              if (planStreakDays > 0)
                Text('🔥 ${l10n.planStreakLabel(planStreakDays)}',
                    style: t.labelMedium
                        ?.copyWith(color: SukoonColors.accent)),
            ],
          ),
        ],
      ),
    );
  }
}
