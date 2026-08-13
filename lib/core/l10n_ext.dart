import 'package:intl/intl.dart';

import 'package:sukoon/constants.dart';

export 'package:sukoon/core/dates.dart' show dateKey;
import 'package:sukoon/l10n/gen/app_localizations.dart';

/// Localized display name for a prayer key ('fajr'...'witr').
String prayerName(AppLocalizations l10n, String key) => switch (key) {
      PrayerKeys.fajr => l10n.prayerFajr,
      PrayerKeys.zuhr => l10n.prayerZuhr,
      PrayerKeys.asr => l10n.prayerAsr,
      PrayerKeys.maghrib => l10n.prayerMaghrib,
      PrayerKeys.isha => l10n.prayerIsha,
      PrayerKeys.witr => l10n.prayerWitr,
      _ => key,
    };

/// 12-hour time like "5:23 AM". Urdu locale keeps Latin digits (CLDR).
String formatTime(String localeName, DateTime t) =>
    DateFormat.jm(localeName).format(t);

/// Short date like "Mon, 11 Aug".
String formatShortDate(String localeName, DateTime d) =>
    DateFormat.MMMEd(localeName).format(d);

/// Countdown like "1h 12m" / "12m 05s".
String formatCountdown(Duration d) {
  if (d.isNegative) return '0m';
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;
  if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
  return '${m}m ${s.toString().padLeft(2, '0')}s';
}
