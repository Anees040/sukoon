package com.anees.sukoon

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

/**
 * Owns the Do-Not-Disturb switch and both notification channels.
 *
 * Design (deviation log in docs/PROJECT_STATE.md): we use
 * INTERRUPTION_FILTER_ALARMS with save/restore of the user's previous
 * filter — simpler and more predictable across OEM skins than mutating
 * the user's PRIORITY policy.
 *
 * Invariants:
 * - The user's own filter is saved only when NO session is active, so an
 *   overlapping prayer never overwrites it with our ALARMS filter.
 * - restoreRinger() is idempotent and safe to call blind (End-now taps,
 *   boot cleanup, master-off).
 */
object DndController {
    const val CHANNEL_SILENCE = "silence_status"
    const val CHANNEL_REMINDERS = "reminders"
    const val NOTIF_ID_SILENCE = 1001
    const val NOTIF_ID_REMINDER = 1002
    const val NOTIF_ID_PRE_AZAN = 1003

    const val ACTION_END_NOW = "com.anees.sukoon.END_NOW"

    private fun nm(ctx: Context): NotificationManager =
        ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    fun isPolicyAccessGranted(ctx: Context): Boolean =
        nm(ctx).isNotificationPolicyAccessGranted

    fun enableSilence(ctx: Context, minutes: Int): Boolean =
        enableSilenceUntil(ctx, System.currentTimeMillis() + minutes * 60_000L)

    /** Switch to alarms-only DND until [endMillis]. Returns false when the
     *  window already passed or DND access is missing. */
    fun enableSilenceUntil(ctx: Context, endMillis: Long): Boolean {
        if (endMillis <= System.currentTimeMillis()) return false
        if (!isPolicyAccessGranted(ctx)) return false
        val manager = nm(ctx)

        if (!NativeState.sessionActive(ctx)) {
            // Remember the user's filter — but never remember a filter we
            // could have set ourselves, or a stuck total-silence state.
            val current = manager.currentInterruptionFilter
            val safe = when (current) {
                NotificationManager.INTERRUPTION_FILTER_PRIORITY -> current
                else -> NotificationManager.INTERRUPTION_FILTER_ALL
            }
            NativeState.setSavedFilter(ctx, safe)
        }

        return try {
            manager.setInterruptionFilter(
                NotificationManager.INTERRUPTION_FILTER_ALARMS
            )
            NativeState.setSession(ctx, true, endMillis)
            true
        } catch (_: SecurityException) {
            false
        }
    }

    /** Put the ringer back how we found it. Idempotent. */
    fun restoreRinger(ctx: Context) {
        NotificationManagerCompat.from(ctx).cancel(NOTIF_ID_SILENCE)
        if (!NativeState.sessionActive(ctx)) return
        if (isPolicyAccessGranted(ctx)) {
            val saved = NativeState.savedFilter(ctx)
            val target = if (saved <= 0) {
                NotificationManager.INTERRUPTION_FILTER_ALL
            } else {
                saved
            }
            try {
                nm(ctx).setInterruptionFilter(target)
            } catch (_: SecurityException) {
                // Access revoked mid-session; drop the session anyway.
            }
        }
        NativeState.setSession(ctx, false, -1L)
    }

    // ---- notifications ----

    private fun ensureChannels(ctx: Context) {
        if (Build.VERSION.SDK_INT < 26) return
        val manager = nm(ctx)
        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL_SILENCE,
                "Silence status",
                NotificationManager.IMPORTANCE_LOW,
            ).apply { setShowBadge(false) }
        )
        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL_REMINDERS,
                "Reminders",
                NotificationManager.IMPORTANCE_DEFAULT,
            )
        )
    }

    private fun notifySafe(ctx: Context, id: Int, n: android.app.Notification) {
        try {
            val compat = NotificationManagerCompat.from(ctx)
            if (compat.areNotificationsEnabled()) compat.notify(id, n)
        } catch (_: SecurityException) {
            // POST_NOTIFICATIONS denied on 13+ — silence still works.
        }
    }

    /** Ongoing low-priority status card with an \"End now\" action. */
    fun showSilenceNotification(
        ctx: Context,
        title: String,
        body: String,
        endLabel: String,
    ) {
        ensureChannels(ctx)
        val endPi = PendingIntent.getBroadcast(
            ctx,
            3100,
            Intent(ctx, RestoreRingerReceiver::class.java).setAction(ACTION_END_NOW),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val openPi = PendingIntent.getActivity(
            ctx,
            3101,
            Intent(ctx, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val n = NotificationCompat.Builder(ctx, CHANNEL_SILENCE)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setContentIntent(openPi)
            .addAction(0, endLabel, endPi)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
        notifySafe(ctx, NOTIF_ID_SILENCE, n)
    }

    /** One-shot reminder / pre-azan heads-up. */
    fun showReminderNotification(ctx: Context, title: String, body: String, id: Int) {
        ensureChannels(ctx)
        val openPi = PendingIntent.getActivity(
            ctx,
            3102,
            Intent(ctx, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val n = NotificationCompat.Builder(ctx, CHANNEL_REMINDERS)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setAutoCancel(true)
            .setContentIntent(openPi)
            .build()
        notifySafe(ctx, id, n)
    }
}
