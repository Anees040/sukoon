package com.anees.sukoon

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Two MethodChannels — keep names in sync with lib/constants.dart
 * (Channels.dnd / Channels.alarms) and the wrappers in lib/native/.
 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "sukoon/dnd")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getStatus" -> result.success(buildStatus())
                    "isPolicyAccessGranted" ->
                        result.success(DndController.isPolicyAccessGranted(this))
                    "openPolicyAccessSettings" -> {
                        try {
                            startActivity(
                                Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
                            )
                        } catch (_: Exception) {
                        }
                        result.success(null)
                    }
                    "enableSilence" -> {
                        val minutes = call.argument<Int>("minutes") ?: 20
                        result.success(DndController.enableSilence(this, minutes))
                    }
                    "restoreRinger" -> {
                        DndController.restoreRinger(this)
                        result.success(null)
                    }
                    "requestPostNotifications" -> {
                        requestPostNotifications()
                        result.success(null)
                    }
                    "requestIgnoreBatteryOptimizations" -> {
                        requestBatteryExemption()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "sukoon/alarms")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "canScheduleExact" ->
                        result.success(PrayerAlarmScheduler.canScheduleExact(this))
                    "requestExactAlarmAccess" -> {
                        requestExactAlarmAccess()
                        result.success(null)
                    }
                    "syncSchedule" -> {
                        val json = call.argument<String>("json") ?: "{}"
                        PrayerAlarmScheduler.syncSchedule(this, json)
                        result.success(null)
                    }
                    "startManualSilence" -> {
                        val minutes = call.argument<Int>("minutes") ?: 20
                        result.success(
                            PrayerAlarmScheduler.startManualSilence(this, minutes)
                        )
                    }
                    "cancelManualSilence" -> {
                        PrayerAlarmScheduler.cancelManualSilence(this)
                        result.success(null)
                    }
                    "cancelAll" -> {
                        PrayerAlarmScheduler.cancelAllAndRestore(this)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun buildStatus(): Map<String, Any> {
        val end = NativeState.sessionEnd(this)
        val active = NativeState.sessionActive(this) &&
            end > System.currentTimeMillis()
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        return mapOf(
            "policyGranted" to DndController.isPolicyAccessGranted(this),
            "exactAllowed" to PrayerAlarmScheduler.canScheduleExact(this),
            "batteryExempt" to pm.isIgnoringBatteryOptimizations(packageName),
            "notifGranted" to NotificationManagerCompat.from(this).areNotificationsEnabled(),
            "sessionActive" to active,
            "sessionEnd" to end,
        )
    }

    private fun requestPostNotifications() {
        if (Build.VERSION.SDK_INT >= 33) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(android.Manifest.permission.POST_NOTIFICATIONS),
                100,
            )
        }
    }

    private fun requestBatteryExemption() {
        try {
            startActivity(
                Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                    .setData(Uri.parse("package:$packageName"))
            )
        } catch (_: Exception) {
            try {
                startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
            } catch (_: Exception) {
            }
        }
    }

    private fun requestExactAlarmAccess() {
        if (Build.VERSION.SDK_INT >= 31) {
            try {
                startActivity(
                    Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM)
                        .setData(Uri.parse("package:$packageName"))
                )
            } catch (_: Exception) {
            }
        }
    }
}
