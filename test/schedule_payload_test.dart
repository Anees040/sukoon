import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sukoon/constants.dart';
import 'package:sukoon/prayer/schedule_payload.dart';

Map<String, DateTime> dayTimes(DateTime base) => {
      PrayerKeys.fajr: DateTime(base.year, base.month, base.day, 5, 0),
      PrayerKeys.zuhr: DateTime(base.year, base.month, base.day, 12, 30),
      PrayerKeys.asr: DateTime(base.year, base.month, base.day, 16, 0),
      PrayerKeys.maghrib: DateTime(base.year, base.month, base.day, 18, 45),
      PrayerKeys.isha: DateTime(base.year, base.month, base.day, 20, 15),
    };

void main() {
  final d1 = DateTime(2026, 8, 11);
  final d2 = DateTime(2026, 8, 12);
  final now = DateTime(2026, 8, 11, 10, 0); // after fajr, before zuhr

  List<PrayerInstant> build({
    bool Function(String)? enabled,
    InstantText? preTitle,
  }) =>
      buildInstants(
        dayMaps: [dayTimes(d1), dayTimes(d2)],
        isEnabled: enabled ?? (_) => true,
        silenceMinutes: 20,
        now: now,
        titleBuilder: (k, s, e) => 'title:$k',
        bodyBuilder: (k, s, e) => 'body:$k',
        preTitleBuilder: preTitle,
      );

  group('buildInstants', () {
    test('drops past prayers, keeps future, sorted ascending', () {
      final list = build();
      expect(list.length, 9); // 10 slots − day-1 fajr (already past)
      expect(list.first.prayer, PrayerKeys.zuhr);
      for (var i = 1; i < list.length; i++) {
        expect(
          list[i].startMillis >= list[i - 1].startMillis,
          isTrue,
          reason: 'instants must be sorted',
        );
      }
    });

    test('skips disabled prayers', () {
      final list = build(enabled: (k) => k != PrayerKeys.asr);
      expect(list.length, 7);
      expect(list.any((i) => i.prayer == PrayerKeys.asr), isFalse);
    });

    test('end = start + silence window', () {
      for (final i in build()) {
        expect(i.endMillis - i.startMillis, 20 * 60 * 1000);
      }
    });

    test('titles/bodies are pre-localized per instant', () {
      final zuhr = build().first;
      expect(zuhr.notifTitle, 'title:${PrayerKeys.zuhr}');
      expect(zuhr.notifBody, 'body:${PrayerKeys.zuhr}');
    });
  });

  group('PrayerInstant.toJson', () {
    test('omits pre-azan strings when null', () {
      final j = build().first.toJson();
      expect(j.containsKey('preTitle'), isFalse);
      expect(j.containsKey('preBody'), isFalse);
      expect(j['start'], isA<int>());
      expect(j['end'], isA<int>());
    });

    test('includes pre-azan strings when provided', () {
      final j = build(preTitle: (k, s, e) => 'pre:$k').first.toJson();
      expect(j['preTitle'], 'pre:${PrayerKeys.zuhr}');
    });
  });

  group('buildSchedulePayload', () {
    test('is versioned, JSON-safe, and matches the Kotlin contract', () {
      final payload = buildSchedulePayload(
        instants: build(),
        silenceMinutes: 20,
        masterEnabled: true,
        notifEnabled: true,
        preAzanMinutes: 10,
        reminderEnabled: true,
        reminderHour: 21,
        reminderMinute: 0,
        reminderTitle: 'Qaza time',
        reminderBody: 'A little tonight?',
        endNowLabel: 'End now',
        delay15Label: '+15m (Jamat later)',
        delay30Label: '+30m',
      );
      expect(payload['version'], 1);

      // Round-trip through real JSON — the native side stores this string.
      final decoded =
          jsonDecode(jsonEncode(payload)) as Map<String, dynamic>;
      expect(decoded['masterEnabled'], isTrue);
      expect(decoded['silenceMinutes'], 20);
      expect(decoded['preAzanMinutes'], 10);
      expect((decoded['instants'] as List).length, 9);
      expect(decoded['reminder']['hour'], 21);
      expect(decoded['reminder']['enabled'], isTrue);
      expect(decoded['strings']['endNow'], 'End now');
      expect(decoded['strings']['delay15'], '+15m (Jamat later)');
      expect(decoded['strings']['delay30'], '+30m');
    });
  });
}
