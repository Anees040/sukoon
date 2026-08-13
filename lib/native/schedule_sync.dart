import 'dart:convert';

import 'package:sukoon/core/l10n_ext.dart';
import 'package:sukoon/core/prefs.dart';
import 'package:sukoon/l10n/gen/app_localizations.dart';
import 'package:sukoon/native/alarms_channel.dart';
import 'package:sukoon/prayer/prayer_service.dart';
import 'package:sukoon/prayer/schedule_payload.dart';

/// Recomputes the 7-day schedule from Prefs and pushes it to the native
/// side. Call on app start, on resume, and after any settings change that
/// affects times, toggles, duration, location, language or reminders.
///
/// Cheap (<10 ms of math) — safe to call generously.
class ScheduleSync {
  ScheduleSync._();

  static Future<void> push(AppLocalizations l10n) async {
    final now = DateTime.now();
    final days = PrayerService.range(
      from: now,
      count: 7,
      lat: Prefs.lat,
      lng: Prefs.lng,
      method: Prefs.method,
      madhab: Prefs.madhab,
    );

    final instants = buildInstants(
      dayMaps: [for (final d in days) d.toMap()],
      isEnabled: (k) => Prefs.masterEnabled && Prefs.prayerEnabled(k),
      silenceMinutes: Prefs.silenceMinutes,
      now: now,
      titleBuilder: (k, s, e) =>
          l10n.notifSilenceTitle(prayerName(l10n, k)),
      bodyBuilder: (k, s, e) =>
          l10n.notifSilenceBody(formatTime(l10n.localeName, e)),
      preTitleBuilder: (k, s, e) =>
          l10n.notifPreAzanTitle(prayerName(l10n, k)),
      preBodyBuilder: (k, s, e) => l10n.notifPreAzanBody(
          prayerName(l10n, k), formatTime(l10n.localeName, s)),
    );

    final payload = buildSchedulePayload(
      instants: instants,
      silenceMinutes: Prefs.silenceMinutes,
      masterEnabled: Prefs.masterEnabled,
      notifEnabled: Prefs.notifEnabled,
      preAzanMinutes: Prefs.preAzanMinutes,
      reminderEnabled: Prefs.reminderEnabled,
      reminderHour: Prefs.reminderHour,
      reminderMinute: Prefs.reminderMinute,
      reminderTitle: l10n.notifReminderTitle,
      reminderBody: l10n.notifReminderBody,
      endNowLabel: l10n.endNow,
    );

    await AlarmsChannel.syncSchedule(jsonEncode(payload));
  }
}
