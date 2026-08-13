import 'package:adhan/adhan.dart';

import 'package:sukoon/constants.dart';

/// One day's five prayer times (local time).
class DayTimes {
  const DayTimes({
    required this.day,
    required this.fajr,
    required this.zuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  final DateTime day;
  final DateTime fajr;
  final DateTime zuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;

  Map<String, DateTime> toMap() => {
        PrayerKeys.fajr: fajr,
        PrayerKeys.zuhr: zuhr,
        PrayerKeys.asr: asr,
        PrayerKeys.maghrib: maghrib,
        PrayerKeys.isha: isha,
      };
}

class NextPrayer {
  const NextPrayer(this.prayer, this.time);
  final String prayer;
  final DateTime time;
}

/// Offline prayer time engine — thin wrapper over the adhan package.
/// Defaults: CalculationMethod.karachi + Madhab.hanafi (Pakistani Asr).
class PrayerService {
  PrayerService._();

  static CalculationParameters params({
    required String method,
    required String madhab,
  }) {
    final CalculationMethod m = switch (method) {
      'mwl' => CalculationMethod.muslim_world_league,
      'isna' => CalculationMethod.north_america,
      'egyptian' => CalculationMethod.egyptian,
      _ => CalculationMethod.karachi,
    };
    final p = m.getParameters();
    p.madhab = madhab == 'shafi' ? Madhab.shafi : Madhab.hanafi;
    return p;
  }

  static DayTimes forDay({
    required DateTime day,
    required double lat,
    required double lng,
    required String method,
    required String madhab,
  }) {
    final t = PrayerTimes(
      Coordinates(lat, lng),
      DateComponents.from(day),
      params(method: method, madhab: madhab),
    );
    return DayTimes(
      day: DateTime(day.year, day.month, day.day),
      fajr: t.fajr,
      zuhr: t.dhuhr,
      asr: t.asr,
      maghrib: t.maghrib,
      isha: t.isha,
    );
  }

  /// The next upcoming prayer relative to [now] (crosses midnight to
  /// tomorrow's Fajr when needed).
  static NextPrayer next({
    required DateTime now,
    required double lat,
    required double lng,
    required String method,
    required String madhab,
  }) {
    for (var addDays = 0; addDays <= 1; addDays++) {
      final day = now.add(Duration(days: addDays));
      final map = forDay(
        day: day,
        lat: lat,
        lng: lng,
        method: method,
        madhab: madhab,
      ).toMap();
      for (final key in PrayerKeys.five) {
        final t = map[key]!;
        if (t.isAfter(now)) return NextPrayer(key, t);
      }
    }
    // Unreachable in practice — tomorrow always has a future Fajr.
    return NextPrayer(
      PrayerKeys.fajr,
      forDay(
        day: now.add(const Duration(days: 1)),
        lat: lat,
        lng: lng,
        method: method,
        madhab: madhab,
      ).fajr,
    );
  }

  /// [count] consecutive days of times starting at [from]'s date.
  static List<DayTimes> range({
    required DateTime from,
    int count = 7,
    required double lat,
    required double lng,
    required String method,
    required String madhab,
  }) {
    return [
      for (var i = 0; i < count; i++)
        forDay(
          day: DateTime(from.year, from.month, from.day + i),
          lat: lat,
          lng: lng,
          method: method,
          madhab: madhab,
        ),
    ];
  }
}
