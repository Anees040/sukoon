/// App-wide constants — the single source of truth for identifiers.
/// If you rename anything here, grep for it in android/ too.
library;

class AppInfo {
  static const appName = 'Sukoon';
  static const appNameUrdu = 'سکون';
  static const version = '0.9.1';
}

/// MethodChannel names — must match MainActivity.kt exactly.
class Channels {
  static const dnd = 'sukoon/dnd';
  static const alarms = 'sukoon/alarms';
}

/// Prayer keys used across DB rows, JSON payloads and l10n lookups.
class PrayerKeys {
  static const fajr = 'fajr';
  static const zuhr = 'zuhr';
  static const asr = 'asr';
  static const maghrib = 'maghrib';
  static const isha = 'isha';
  static const witr = 'witr';

  /// The five daily obligatory prayers, in order.
  static const five = [fajr, zuhr, asr, maghrib, isha];

  /// Qaza ledger rows (witr row used when enabled — Hanafi default ON).
  static const six = [fajr, zuhr, asr, maghrib, isha, witr];
}

class Kaaba {
  static const lat = 21.422487;
  static const lng = 39.826206;
}

/// shared_preferences keys (Dart side only; native side uses "sukoon_state").
class PrefKeys {
  static const localeMode = 'localeMode'; // system | en | ur
  static const masterEnabled = 'masterEnabled';
  static const silenceMinutes = 'silenceMinutes'; // 15 | 20 | 30
  static const method = 'calcMethod'; // karachi | mwl | isna | egyptian
  static const madhab = 'asrMadhab'; // hanafi | shafi
  static const lat = 'lat';
  static const lng = 'lng';
  static const locationLabel = 'locationLabel';
  static const prayerEnabledPrefix = 'enabled_'; // + prayer key
  static const witrEnabled = 'witrEnabled';
  static const primerShown = 'primerShown';
  static const batterySheetShown = 'batterySheetShown';
  static const notifEnabled = 'silenceNotifEnabled';
  static const preAzanMinutes = 'preAzanMinutes'; // 0 = off, else 10|15|30
  static const reminderEnabled = 'qazaReminderEnabled';
  static const reminderHour = 'qazaReminderHour';
  static const reminderMinute = 'qazaReminderMinute';
  static const dailyTargetSets = 'dailyTargetSets';
  static const minutesPerQaza = 'minutesPerQaza';
  static const favoriteCities = 'favoriteCities';
  static const qazaWizardDone = 'qazaWizardDone';
}

class Defaults {
  static const silenceMinutes = 20;
  static const method = 'karachi';
  static const madhab = 'hanafi';

  /// Islamabad — used until location/city is set.
  static const lat = 33.6844;
  static const lng = 73.0479;
  static const locationLabel = 'Islamabad';

  static const dailyTargetSets = 1;
  static const minutesPerQaza = 5;
  static const reminderHour = 21; // 9:00 PM
  static const reminderMinute = 0;
}
