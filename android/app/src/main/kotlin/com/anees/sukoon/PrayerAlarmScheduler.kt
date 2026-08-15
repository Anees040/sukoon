package com.anees.sukoon

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import org.json.JSONObject
import java.text.DateFormat
import java.util.Calendar
import java.util.Date

/**
 * Reads the payload stored by Dart (see lib/prayer/schedule_payload.dart,
 * version 1) and (re)arms every alarm. Runs with no Flutter engine — boot
 * receivers call straight into here.
 *
 * Request codes (stable, cancelled by recreating matching PendingIntents):
 *   1000+i silence starts · 2000+i ringer restores · 3000 manual end
 *   4000 nightly reminder · 6000+i pre-azan heads-ups
 */
object PrayerAlarmScheduler {
    const val ACTION_PRAYER_START = "com.anees.sukoon.PRAYER_START"
    const val ACTION_RESTORE = "com.anees.sukoon.RESTORE"
    const val ACTION_REMINDER = "com.anees.sukoon.REMINDER"

    private const val RC_START_BASE = 1000
    private const val RC_END_BASE = 2000
    private const val RC_MANUAL_END = 3000
    private const val RC_REMINDER = 4000
    private const val RC_PRE_BASE = 6000

    /** 7 days × 5 prayers = 35; headroom for safety. */
    private const val MAX_INSTANTS = 50

    private fun am(ctx: Context): AlarmManager =
        ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager

    fun canScheduleExact(ctx: Context): Boolean =
        if (Build.VERSION.SDK_INT >= 31) am(ctx).canScheduleExactAlarms() else true

    fun syncSchedule(ctx: Context, json: String) {
        NativeState.setScheduleJson(ctx, json)
        scheduleAll(ctx)
    }

    // ---- plumbing ----

    private fun broadcastPi(ctx: Context, code: Int, intent: Intent): PendingIntent =
        PendingIntent.getBroadcast(
            ctx,
            code,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

    /** Exact when allowed, inexact otherwise — silence a few minutes late
     *  beats no silence at all. */
    private fun exactOrBest(ctx: Context, atMillis: Long, pi: PendingIntent) {
        val manager = am(ctx)
        try {
            if (canScheduleExact(ctx)) {
                manager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, atMillis, pi)
            } else {
                manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, atMillis, pi)
            }
        } catch (_: SecurityException) {
            manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, atMillis, pi)
        }
    }

    private fun startIntent(ctx: Context) =
        Intent(ctx, PrayerAlarmReceiver::class.java).setAction(ACTION_PRAYER_START)

    private fun restoreIntent(ctx: Context) =
        Intent(ctx, RestoreRingerReceiver::class.java).setAction(ACTION_RESTORE)

    private fun reminderIntent(ctx: Context) =
        Intent(ctx, ReminderReceiver::class.java).setAction(ACTION_REMINDER)

    fun cancelScheduledAlarms(ctx: Context) {
        val manager = am(ctx)
        for (i in 0 until MAX_INSTANTS) {
            manager.cancel(broadcastPi(ctx, RC_START_BASE + i, startIntent(ctx)))
            manager.cancel(broadcastPi(ctx, RC_END_BASE + i, restoreIntent(ctx)))
            manager.cancel(broadcastPi(ctx, RC_PRE_BASE + i, reminderIntent(ctx)))
        }
        manager.cancel(broadcastPi(ctx, RC_REMINDER, reminderIntent(ctx)))
    }

    // ---- the big one ----

    fun scheduleAll(ctx: Context) {
        cancelScheduledAlarms(ctx)
        val json = NativeState.scheduleJson(ctx) ?: return
        val payload = try {
            JSONObject(json)
        } catch (_: Exception) {
            return
        }
        if (!payload.optBoolean("masterEnabled", false)) return

        val now = System.currentTimeMillis()
        val notifEnabled = payload.optBoolean("notifEnabled", true)
        val preAzanMinutes = payload.optInt("preAzanMinutes", 0)
        
        val strings = payload.optJSONObject("strings")
        val endNowLabel = strings?.optString("endNow")
            .let { if (it.isNullOrEmpty()) "End now" else it }
        val delay15Label = strings?.optString("delay15")
            .let { if (it.isNullOrEmpty()) "+15m" else it }
        val delay30Label = strings?.optString("delay30")
            .let { if (it.isNullOrEmpty()) "+30m" else it }
            
        val instants = payload.optJSONArray("instants") ?: return

        var idx = 0
        for (i in 0 until instants.length()) {
            if (idx >= MAX_INSTANTS) break
            val inst = instants.optJSONObject(i) ?: continue
            val start = inst.optLong("start", -1L)
            val end = inst.optLong("end", -1L)
            if (end <= now) continue // window fully in the past

            if (start > now) {
                val si = startIntent(ctx)
                    .putExtra("prayer", inst.optString("prayer"))
                    .putExtra("end", end)
                    .putExtra("title", inst.optString("notifTitle"))
                    .putExtra("body", inst.optString("notifBody"))
                    .putExtra("notif", notifEnabled)
                    .putExtra("endLabel", endNowLabel)
                    .putExtra("delay15Label", delay15Label)
                    .putExtra("delay30Label", delay30Label)
                exactOrBest(ctx, start, broadcastPi(ctx, RC_START_BASE + idx, si))

                if (preAzanMinutes > 0 && inst.has("preTitle")) {
                    val preAt = start - preAzanMinutes * 60_000L
                    if (preAt > now) {
                        val pi = reminderIntent(ctx)
                            .putExtra("title", inst.optString("preTitle"))
                            .putExtra("body", inst.optString("preBody"))
                            .putExtra("id", DndController.NOTIF_ID_PRE_AZAN)
                        exactOrBest(ctx, preAt, broadcastPi(ctx, RC_PRE_BASE + idx, pi))
                    }
                }
            }

            // Restore alarm is armed even when start already passed — it is
            // the safety net that un-silences the phone.
            exactOrBest(ctx, end, broadcastPi(ctx, RC_END_BASE + idx, restoreIntent(ctx)))
            idx++
        }

        val reminder = payload.optJSONObject("reminder")
        if (reminder != null && reminder.optBoolean("enabled", false)) {
            val cal = Calendar.getInstance().apply {
                set(Calendar.HOUR_OF_DAY, reminder.optInt("hour", 21))
                set(Calendar.MINUTE, reminder.optInt("minute", 0))
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
                if (timeInMillis <= now) add(Calendar.DAY_OF_YEAR, 1)
            }
            val ri = reminderIntent(ctx)
                .putExtra("title", reminder.optString("title"))
                .putExtra("body", reminder.optString("body"))
                .putExtra("id", DndController.NOTIF_ID_REMINDER)
            am(ctx).setInexactRepeating(
                AlarmManager.RTC_WAKEUP,
                cal.timeInMillis,
                AlarmManager.INTERVAL_DAY,
                broadcastPi(ctx, RC_REMINDER, ri),
            )
        }
    }

    // ---- masjid mode ----

    fun startManualSilence(ctx: Context, minutes: Int): Boolean {
        val end = System.currentTimeMillis() + minutes * 60_000L
        if (!DndController.enableSilenceUntil(ctx, end)) return false

        val endLabel = try {
            NativeState.scheduleJson(ctx)
                ?.let { JSONObject(it).optJSONObject("strings")?.optString("endNow") }
        } catch (_: Exception) {
            null
        }.let { if (it.isNullOrEmpty()) "End now" else it }

        val until = DateFormat.getTimeInstance(DateFormat.SHORT).format(Date(end))
        DndController.showSilenceNotification(ctx, "Sukoon \uD83D\uDD4C", until, endLabel)
        exactOrBest(ctx, end, broadcastPi(ctx, RC_MANUAL_END, restoreIntent(ctx)))
        return true
    }

    fun cancelManualSilence(ctx: Context) {
        am(ctx).cancel(broadcastPi(ctx, RC_MANUAL_END, restoreIntent(ctx)))
        DndController.restoreRinger(ctx)
    }

    /** Master switch off: drop every alarm and un-silence if needed. */
    fun cancelAllAndRestore(ctx: Context) {
        cancelScheduledAlarms(ctx)
        am(ctx).cancel(broadcastPi(ctx, RC_MANUAL_END, restoreIntent(ctx)))
        DndController.restoreRinger(ctx)
    }

    /** After reboot/time change: re-arm alarms, finish interrupted sessions. */
    fun rescheduleAfterBoot(ctx: Context) {
        scheduleAll(ctx)
        if (NativeState.sessionActive(ctx)) {
            val end = NativeState.sessionEnd(ctx)
            if (end <= System.currentTimeMillis()) {
                DndController.restoreRinger(ctx)
            } else {
                exactOrBest(ctx, end, broadcastPi(ctx, RC_MANUAL_END, restoreIntent(ctx)))
            }
        }
    }
}
