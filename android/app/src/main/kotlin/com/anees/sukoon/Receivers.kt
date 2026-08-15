package com.anees.sukoon

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * All five receivers. Pure Kotlin — they must never spin up a Flutter
 * engine (cold-start would blow past the broadcast time budget and the
 * battery budget). Everything they need arrives in intent extras or
 * NativeState.
 */

/** Azan time: silence the phone, optionally show the status card. */
class PrayerAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val ctx = context.applicationContext
        val end = intent.getLongExtra("end", -1L)
        if (end <= System.currentTimeMillis()) return // fired too late
        if (!DndController.enableSilenceUntil(ctx, end)) return
        if (intent.getBooleanExtra("notif", true)) {
            DndController.showSilenceNotification(
                ctx,
                intent.getStringExtra("title") ?: "Sukoon",
                intent.getStringExtra("body") ?: "",
                intent.getStringExtra("endLabel") ?: "End now",
                intent.getStringExtra("prayer"),
                intent.getStringExtra("delay15Label") ?: "+15m",
                intent.getStringExtra("delay30Label") ?: "+30m",
            )
        }
    }
}

/** 
 * Handles taps on the "+15m" and "+30m" notification actions.
 * Unsilences immediately, updates SharedPreferences so Dart sees the new offset,
 * and schedules a one-off alarm to re-silence later.
 */
class DelayJamatReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val ctx = context.applicationContext
        val prayerKey = intent.getStringExtra("prayer")
        val delayMins = intent.getIntExtra("delay", 15)
        
        // 1. Immediately restore ringer (user tapped this because it's not jamat yet)
        DndController.restoreRinger(ctx)
        
        // 2. Add to SharedPreferences so Dart reads it next time it opens
        if (!prayerKey.isNullOrEmpty()) {
            val prefs = ctx.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val prefKey = "flutter_jamatOffset_$prayerKey"
            // Dart's shared_preferences stores ints as Longs natively
            val currentOffset = prefs.getLong(prefKey, 0L)
            prefs.edit().putLong(prefKey, currentOffset + delayMins).apply()
        }
        
        // 3. Schedule a one-off delayed silence for the remaining time
        val newStart = System.currentTimeMillis() + delayMins * 60_000L
        val silenceDuration = 30 * 60_000L // Assume 30 mins for the delayed silence
        val newEnd = newStart + silenceDuration
        
        val si = Intent(ctx, PrayerAlarmReceiver::class.java).setAction(PrayerAlarmScheduler.ACTION_PRAYER_START)
            .putExtra("end", newEnd)
            .putExtra("title", "Sukoon \uD83D\uDD4C")
            .putExtra("body", "") // Let the default strings apply
            .putExtra("notif", true)
            .putExtra("endLabel", "End now")
            // Intentionally not passing prayerKey so the +15m/+30m buttons don't loop endlessly
            
        val pi = PendingIntent.getBroadcast(
            ctx, 5000 + delayMins, si, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val manager = ctx.getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager
        try {
            if (PrayerAlarmScheduler.canScheduleExact(ctx)) {
                manager.setExactAndAllowWhileIdle(android.app.AlarmManager.RTC_WAKEUP, newStart, pi)
            } else {
                manager.setAndAllowWhileIdle(android.app.AlarmManager.RTC_WAKEUP, newStart, pi)
            }
        } catch (_: SecurityException) {
            manager.setAndAllowWhileIdle(android.app.AlarmManager.RTC_WAKEUP, newStart, pi)
        }
    }
}

/** Window end or End-now tap: put the ringer back. */
class RestoreRingerReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        DndController.restoreRinger(context.applicationContext)
    }
}

/** Nightly qaza reminder and pre-azan heads-up (extras carry the text). */
class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val ctx = context.applicationContext
        val title = intent.getStringExtra("title") ?: return
        val body = intent.getStringExtra("body") ?: ""
        val id = intent.getIntExtra("id", DndController.NOTIF_ID_REMINDER)
        DndController.showReminderNotification(ctx, title, body, id)
    }
}

/** Reboot wipes AlarmManager — re-arm everything from stored JSON. */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        if (action != Intent.ACTION_BOOT_COMPLETED &&
            action != "android.intent.action.QUICKBOOT_POWERON"
        ) {
            return
        }
        PrayerAlarmScheduler.rescheduleAfterBoot(context.applicationContext)
    }
}

/**
 * Timezone/clock change: stored epochs stay correct for the location, but
 * AlarmManager RTC alarms should be re-armed. (Dart recomputes times from
 * coordinates on next app open — v0 limitation, documented.)
 */
class TimezoneChangedReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        if (action != Intent.ACTION_TIMEZONE_CHANGED &&
            action != Intent.ACTION_TIME_CHANGED
        ) {
            return
        }
        PrayerAlarmScheduler.rescheduleAfterBoot(context.applicationContext)
    }
}
