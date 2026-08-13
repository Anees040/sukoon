import 'package:flutter/material.dart';

import 'package:sukoon/constants.dart';
import 'package:sukoon/core/l10n_ext.dart';
import 'package:sukoon/core/prefs.dart';
import 'package:sukoon/data/city_repository.dart';
import 'package:sukoon/features/common/widgets.dart';
import 'package:sukoon/l10n/gen/app_localizations.dart';
import 'package:sukoon/native/schedule_sync.dart';
import 'package:sukoon/prayer/prayer_service.dart';
import 'package:sukoon/theme.dart';

class CityDetail extends StatelessWidget {
  const CityDetail({super.key, required this.city});

  final City city;

  Future<void> _useCity(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final isUrdu = l10n.localeName == 'ur';
    final label = isUrdu ? city.nameUr : city.nameEn;

    await Prefs.setLocation(city.lat, city.lng, city.nameEn);
    await ScheduleSync.push(l10n);

    navigator.pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.citySetDone(label))));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final isUrdu = l10n.localeName == 'ur';

    final days = PrayerService.range(
      from: DateTime.now(),
      count: 7,
      lat: city.lat,
      lng: city.lng,
      method: Prefs.method,
      madhab: Prefs.madhab,
    );
    final today = days.first;
    final upcoming = days.sublist(1);

    return Scaffold(
      appBar: AppBar(
        title: Text(isUrdu ? city.nameUr : city.nameEn),
      ),
      body: SafeArea(
        child: ListView(
          padding: kScreenPad,
          children: [
            Text(isUrdu ? city.nameEn : city.nameUr,
                style:
                    t.bodyMedium?.copyWith(color: SukoonColors.textFaint)),
            const SizedBox(height: 12),

            // Today
            SectionCard(
              color: SukoonColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.cityToday,
                      style: t.labelMedium
                          ?.copyWith(color: SukoonColors.accent)),
                  const SizedBox(height: 8),
                  for (final entry in today.toMap().entries)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(prayerName(l10n, entry.key),
                                style: t.titleMedium),
                          ),
                          Text(
                              formatTime(l10n.localeName, entry.value),
                              style: t.titleMedium
                                  ?.copyWith(color: SukoonColors.text)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Next 6 days
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.cityUpcoming,
                      style: t.labelMedium
                          ?.copyWith(color: SukoonColors.textSecondary)),
                  const SizedBox(height: 8),
                  for (final d in upcoming)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              formatShortDate(l10n.localeName, d.day),
                              style: t.labelMedium?.copyWith(
                                  color: SukoonColors.textSecondary)),
                          const SizedBox(height: 2),
                          Wrap(
                            spacing: 10,
                            children: [
                              for (final k in PrayerKeys.five)
                                Text(
                                  '${prayerName(l10n, k)} ${formatTime(l10n.localeName, d.toMap()[k]!)}',
                                  style: t.labelSmall?.copyWith(
                                      color: SukoonColors.textFaint),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            FilledButton.icon(
              icon: const Icon(Icons.my_location),
              label: Text(l10n.citySetLocation),
              onPressed: () => _useCity(context),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
