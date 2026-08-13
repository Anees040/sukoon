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
            )
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
