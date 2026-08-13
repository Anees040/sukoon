import 'package:flutter/services.dart';

import 'package:sukoon/constants.dart';

/// Snapshot of all permission/session state the UI cares about.
/// Comes from Kotlin getStatus() — defensive defaults everywhere.
class DndStatus {
  const DndStatus({
    required this.policyGranted,
    required this.exactAllowed,
    required this.batteryExempt,
    required this.notifGranted,
    required this.sessionActive,
    required this.sessionEndMillis,
  });

  final bool policyGranted;
  final bool exactAllowed;
  final bool batteryExempt;
  final bool notifGranted;
  final bool sessionActive;

  /// Epoch millis when the current silence ends, or -1.
  final int sessionEndMillis;

  bool get coreGranted => policyGranted && exactAllowed;

  static const unknown = DndStatus(
    policyGranted: false,
    exactAllowed: false,
    batteryExempt: false,
    notifGranted: false,
    sessionActive: false,
    sessionEndMillis: -1,
  );

  factory DndStatus.fromMap(Map<Object?, Object?>? m) {
    if (m == null) return unknown;
    bool b(String k) => m[k] == true;
    return DndStatus(
      policyGranted: b('policyGranted'),
      exactAllowed: b('exactAllowed'),
      batteryExempt: b('batteryExempt'),
      notifGranted: b('notifGranted'),
      sessionActive: b('sessionActive'),
      sessionEndMillis: (m['sessionEnd'] as num?)?.toInt() ?? -1,
    );
  }
}

/// Dart wrapper for MethodChannel "sukoon/dnd".
/// Never throws to the UI — failures degrade to safe defaults.
class DndChannel {
  DndChannel._();

  static const _ch = MethodChannel(Channels.dnd);

  static Future<DndStatus> getStatus() async {
    try {
      final m = await _ch.invokeMethod<Map<Object?, Object?>>('getStatus');
      return DndStatus.fromMap(m);
    } catch (_) {
      return DndStatus.unknown;
    }
  }

  static Future<bool> isPolicyAccessGranted() async {
    try {
      return await _ch.invokeMethod<bool>('isPolicyAccessGranted') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens the system Do-Not-Disturb access settings page.
  static Future<void> openPolicyAccessSettings() async {
    try {
      await _ch.invokeMethod<void>('openPolicyAccessSettings');
    } catch (_) {}
  }

  /// Returns true if silence was applied (false = access denied).
  static Future<bool> enableSilence(int minutes) async {
    try {
      return await _ch
              .invokeMethod<bool>('enableSilence', {'minutes': minutes}) ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> restoreRinger() async {
    try {
      await _ch.invokeMethod<void>('restoreRinger');
    } catch (_) {}
  }

  static Future<void> requestPostNotifications() async {
    try {
      await _ch.invokeMethod<void>('requestPostNotifications');
    } catch (_) {}
  }

  static Future<void> requestIgnoreBatteryOptimizations() async {
    try {
      await _ch.invokeMethod<void>('requestIgnoreBatteryOptimizations');
    } catch (_) {}
  }
}
