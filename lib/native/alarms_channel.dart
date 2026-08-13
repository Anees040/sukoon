import 'package:flutter/services.dart';

import 'package:sukoon/constants.dart';

/// Dart wrapper for MethodChannel "sukoon/alarms".
/// Never throws to the UI — failures degrade to safe defaults.
class AlarmsChannel {
  AlarmsChannel._();

  static const _ch = MethodChannel(Channels.alarms);

  /// AlarmManager.canScheduleExactAlarms() (true below API 31).
  static Future<bool> canScheduleExact() async {
    try {
      return await _ch.invokeMethod<bool>('canScheduleExact') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens the system "Alarms & reminders" special-access page.
  static Future<void> requestExactAlarmAccess() async {
    try {
      await _ch.invokeMethod<void>('requestExactAlarmAccess');
    } catch (_) {}
  }

  /// Stores the payload JSON natively and (re)schedules every alarm.
  /// See lib/prayer/schedule_payload.dart for the shape.
  static Future<void> syncSchedule(String json) async {
    try {
      await _ch.invokeMethod<void>('syncSchedule', {'json': json});
    } catch (_) {}
  }

  /// Masjid Mode: silence NOW for [minutes] via the native pipeline.
  /// Returns false when DND access is denied.
  static Future<bool> startManualSilence(int minutes) async {
    try {
      return await _ch.invokeMethod<bool>(
              'startManualSilence', {'minutes': minutes}) ??
          false;
    } catch (_) {
      return false;
    }
  }

  /// Cancels a running Masjid Mode session and restores the ringer.
  static Future<void> cancelManualSilence() async {
    try {
      await _ch.invokeMethod<void>('cancelManualSilence');
    } catch (_) {}
  }

  /// Master switch OFF: cancel everything; restore ringer if silenced.
  static Future<void> cancelAll() async {
    try {
      await _ch.invokeMethod<void>('cancelAll');
    } catch (_) {}
  }
}
