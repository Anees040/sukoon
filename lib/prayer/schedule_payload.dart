/// Builds the JSON payload Dart pushes to the native side
/// (MethodChannel sukoon/alarms → native SharedPreferences "sukoon_state").
///
/// PURE DART — no Flutter imports — unit tested in
/// test/schedule_payload_test.dart. Keep it that way.
library;

import 'package:sukoon/constants.dart';

/// A single silence window: DND on at [startMillis], ringer restored at
/// [endMillis]. Notification strings are pre-localized by Dart because the
/// Kotlin receivers have no access to Flutter localization.
class PrayerInstant {
  const PrayerInstant({
    required this.prayer,
    required this.startMillis,
    required this.endMillis,
    required this.notifTitle,
    required this.notifBody,
    this.preTitle,
    this.preBody,
  });

  final String prayer;
  final int startMillis;
  final int endMillis;
  final String notifTitle;
  final String notifBody;

  /// Pre-azan reminder strings (used only when payload preAzanMinutes > 0).
  final String? preTitle;
  final String? preBody;

  Map<String, Object?> toJson() => {
        'prayer': prayer,
        'start': startMillis,
        'end': endMillis,
        'notifTitle': notifTitle,
        'notifBody': notifBody,
        if (preTitle != null) 'preTitle': preTitle,
        if (preBody != null) 'preBody': preBody,
      };
}

typedef InstantText = String Function(
    String prayerKey, DateTime start, DateTime end);

/// Flattens up to 7 days of prayer time maps into future-only, enabled-only,
/// sorted silence instants.
List<PrayerInstant> buildInstants({
  required List<Map<String, DateTime>> dayMaps,
  required bool Function(String prayerKey) isEnabled,
  required int silenceMinutes,
  required DateTime now,
  required InstantText titleBuilder,
  required InstantText bodyBuilder,
  InstantText? preTitleBuilder,
  InstantText? preBodyBuilder,
}) {
  final out = <PrayerInstant>[];
  for (final dayMap in dayMaps) {
    for (final key in PrayerKeys.five) {
      final start = dayMap[key];
      if (start == null) continue;
      if (!isEnabled(key)) continue;
      if (!start.isAfter(now)) continue;
      final end = start.add(Duration(minutes: silenceMinutes));
      out.add(PrayerInstant(
        prayer: key,
        startMillis: start.millisecondsSinceEpoch,
        endMillis: end.millisecondsSinceEpoch,
        notifTitle: titleBuilder(key, start, end),
        notifBody: bodyBuilder(key, start, end),
        preTitle: preTitleBuilder?.call(key, start, end),
        preBody: preBodyBuilder?.call(key, start, end),
      ));
    }
  }
  out.sort((a, b) => a.startMillis.compareTo(b.startMillis));
  return out;
}

/// Envelope stored verbatim by the native side. Version it if the shape
/// ever changes — receivers parse this with org.json.
Map<String, Object?> buildSchedulePayload({
  required List<PrayerInstant> instants,
  required int silenceMinutes,
  required bool masterEnabled,
  required bool notifEnabled,
  required int preAzanMinutes,
  required bool reminderEnabled,
  required int reminderHour,
  required int reminderMinute,
  required String reminderTitle,
  required String reminderBody,
  required String endNowLabel,
}) {
  return {
    'version': 1,
    'masterEnabled': masterEnabled,
    'silenceMinutes': silenceMinutes,
    'notifEnabled': notifEnabled,
    'preAzanMinutes': preAzanMinutes,
    'instants': [for (final i in instants) i.toJson()],
    'reminder': {
      'enabled': reminderEnabled,
      'hour': reminderHour,
      'minute': reminderMinute,
      'title': reminderTitle,
      'body': reminderBody,
    },
    'strings': {'endNow': endNowLabel},
  };
}
