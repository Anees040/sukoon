import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sukoon/constants.dart';

/// Typed wrapper over shared_preferences (Dart-side settings only — the
/// native side keeps its own "sukoon_state" store fed via ScheduleSync).
///
/// Call [init] once before runApp. Screens listen to [revision] to rebuild
/// after any setting changes.
class Prefs {
  Prefs._();

  static late SharedPreferences _p;

  /// Bumped on every write.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  static Future<void> init() async {
    _p = await SharedPreferences.getInstance();
  }

  static void _bump() => revision.value++;

  // ---- locale ----
  static String get localeMode =>
      _p.getString(PrefKeys.localeMode) ?? 'system';
  static Future<void> setLocaleMode(String v) async {
    await _p.setString(PrefKeys.localeMode, v);
    _bump();
  }

  // ---- silent core ----
  static bool get masterEnabled => _p.getBool(PrefKeys.masterEnabled) ?? true;
  static Future<void> setMasterEnabled(bool v) async {
    await _p.setBool(PrefKeys.masterEnabled, v);
    _bump();
  }

  static int get silenceMinutes =>
      _p.getInt(PrefKeys.silenceMinutes) ?? Defaults.silenceMinutes;
  static Future<void> setSilenceMinutes(int v) async {
    await _p.setInt(PrefKeys.silenceMinutes, v);
    _bump();
  }

  static bool prayerEnabled(String prayerKey) =>
      _p.getBool('${PrefKeys.prayerEnabledPrefix}$prayerKey') ?? true;
  static Future<void> setPrayerEnabled(String prayerKey, bool v) async {
    await _p.setBool('${PrefKeys.prayerEnabledPrefix}$prayerKey', v);
    _bump();
  }

  // ---- prayer calculation ----
  static String get method => _p.getString(PrefKeys.method) ?? Defaults.method;
  static Future<void> setMethod(String v) async {
    await _p.setString(PrefKeys.method, v);
    _bump();
  }

  static String get madhab => _p.getString(PrefKeys.madhab) ?? Defaults.madhab;
  static Future<void> setMadhab(String v) async {
    await _p.setString(PrefKeys.madhab, v);
    _bump();
  }

  // ---- location ----
  static double get lat => _p.getDouble(PrefKeys.lat) ?? Defaults.lat;
  static double get lng => _p.getDouble(PrefKeys.lng) ?? Defaults.lng;
  static String get locationLabel =>
      _p.getString(PrefKeys.locationLabel) ?? Defaults.locationLabel;
  static Future<void> setLocation(
      double lat, double lng, String label) async {
    await _p.setDouble(PrefKeys.lat, lat);
    await _p.setDouble(PrefKeys.lng, lng);
    await _p.setString(PrefKeys.locationLabel, label);
    _bump();
  }

  // ---- tracker / qaza ----
  static bool get witrEnabled => _p.getBool(PrefKeys.witrEnabled) ?? true;
  static Future<void> setWitrEnabled(bool v) async {
    await _p.setBool(PrefKeys.witrEnabled, v);
    _bump();
  }

  static bool get qazaWizardDone =>
      _p.getBool(PrefKeys.qazaWizardDone) ?? false;
  static Future<void> setQazaWizardDone(bool v) async {
    await _p.setBool(PrefKeys.qazaWizardDone, v);
    _bump();
  }

  static int get dailyTargetSets =>
      _p.getInt(PrefKeys.dailyTargetSets) ?? Defaults.dailyTargetSets;
  static Future<void> setDailyTargetSets(int v) async {
    await _p.setInt(PrefKeys.dailyTargetSets, v);
    _bump();
  }

  static int get minutesPerQaza =>
      _p.getInt(PrefKeys.minutesPerQaza) ?? Defaults.minutesPerQaza;
  static Future<void> setMinutesPerQaza(int v) async {
    await _p.setInt(PrefKeys.minutesPerQaza, v);
    _bump();
  }

  // ---- jamat offset ----
  /// Minutes after adhan to shift auto-silent (per prayer).
  static int jamatOffset(String prayerKey) =>
      _p.getInt('${PrefKeys.jamatOffsetPrefix}$prayerKey') ??
      Defaults.jamatOffset[prayerKey] ??
      0;
  static Future<void> setJamatOffset(String prayerKey, int minutes) async {
    await _p.setInt('${PrefKeys.jamatOffsetPrefix}$prayerKey', minutes);
    _bump();
  }

  // ---- notifications & reminders ----
  static bool get notifEnabled => _p.getBool(PrefKeys.notifEnabled) ?? true;
  static Future<void> setNotifEnabled(bool v) async {
    await _p.setBool(PrefKeys.notifEnabled, v);
    _bump();
  }

  static int get preAzanMinutes => _p.getInt(PrefKeys.preAzanMinutes) ?? 0;
  static Future<void> setPreAzanMinutes(int v) async {
    await _p.setInt(PrefKeys.preAzanMinutes, v);
    _bump();
  }

  static bool get reminderEnabled =>
      _p.getBool(PrefKeys.reminderEnabled) ?? false;
  static Future<void> setReminderEnabled(bool v) async {
    await _p.setBool(PrefKeys.reminderEnabled, v);
    _bump();
  }

  static int get reminderHour =>
      _p.getInt(PrefKeys.reminderHour) ?? Defaults.reminderHour;
  static int get reminderMinute =>
      _p.getInt(PrefKeys.reminderMinute) ?? Defaults.reminderMinute;
  static Future<void> setReminderTime(int hour, int minute) async {
    await _p.setInt(PrefKeys.reminderHour, hour);
    await _p.setInt(PrefKeys.reminderMinute, minute);
    _bump();
  }

  // ---- one-time flags ----
  static bool get primerShown => _p.getBool(PrefKeys.primerShown) ?? false;
  static Future<void> setPrimerShown() async {
    await _p.setBool(PrefKeys.primerShown, true);
    _bump();
  }

  static bool get batterySheetShown =>
      _p.getBool(PrefKeys.batterySheetShown) ?? false;
  static Future<void> setBatterySheetShown() async {
    await _p.setBool(PrefKeys.batterySheetShown, true);
    _bump();
  }

  // ---- cities ----
  static List<String> get favoriteCities =>
      _p.getStringList(PrefKeys.favoriteCities) ?? const [];
  static Future<void> toggleFavoriteCity(String id) async {
    final list = [...favoriteCities];
    if (!list.remove(id)) list.add(id);
    await _p.setStringList(PrefKeys.favoriteCities, list);
    _bump();
  }
}
