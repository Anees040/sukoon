import 'package:flutter/material.dart';

import 'package:sukoon/core/dates.dart';
import 'package:sukoon/theme.dart';

/// Month heatmap — one cell per day, intensity = prayers done (0–5).
/// Widget-based (not CustomPainter) for reliable taps and RTL support.
class MonthHeatmap extends StatelessWidget {
  const MonthHeatmap({
    super.key,
    required this.year,
    required this.month,
    required this.doneCountByDate,
    required this.periodDays,
    required this.today,
    required this.selected,
    required this.onTapDay,
  });

  final int year;
  final int month;

  /// dateKey → number of prayers prayed/jamaat that day (0–5).
  final Map<String, int> doneCountByDate;
  final Set<String> periodDays;
  final DateTime today;
  final DateTime selected;
  final void Function(DateTime day) onTapDay;

  // Gold ramp (Sukoon Gold palette): card -> deep bronze -> gold-brown
  // (#C78225 from the logo) -> full gold accent. Reads as "more prayed,
  // more golden" on the deep-teal background.
  static const _fillSteps = [
    SukoonColors.card, // 0
    Color(0xFF3A2E14), // 1
    Color(0xFF5C4517), // 2
    Color(0xFF8A671F), // 3
    SukoonColors.goldDeep, // 4 (#C78225)
    SukoonColors.accent, // 5 (#EDB24E)
  ];

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final todayOnly = dateOnly(today);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemCount: daysInMonth,
      itemBuilder: (context, i) {
        final day = DateTime(year, month, i + 1);
        final key = dateKey(day);
        final isFuture = day.isAfter(todayOnly);
        final isPeriod = periodDays.contains(key);
        final isToday = key == dateKey(todayOnly);
        final isSelected = key == dateKey(selected);
        final done = (doneCountByDate[key] ?? 0).clamp(0, 5);

        final fill = isFuture
            ? Colors.transparent
            : isPeriod
                ? SukoonColors.cardRaised
                : _fillSteps[done];

        return InkWell(
          onTap: isFuture ? null : () => onTapDay(day),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? SukoonColors.lime
                    : isToday
                        ? SukoonColors.accent
                        : isFuture
                            ? SukoonColors.card
                            : Colors.transparent,
                width: isSelected || isToday ? 1.6 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '${i + 1}',
              style: t.labelSmall?.copyWith(
                color: isFuture
                    ? SukoonColors.textFaint
                    : done >= 4
                        ? SukoonColors.bg
                        : SukoonColors.text,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        );
      },
    );
  }
}
