package com.anees.sukoon

import android.content.Context
import android.content.SharedPreferences

/**
 * Native-side persistent state (SharedPreferences "sukoon_state").
 *
 * Receivers run without a Flutter engine, so everything they need — the
 * schedule payload, the user's pre-silence ringer filter, and the active
 * session — lives here, never in Flutter's own prefs.
 */
object NativeState {
    private const val PREFS = "sukoon_state"
    private const val KEY_SCHEDULE_JSON = "schedule_json"
    private const val KEY_SAVED_FILTER = "saved_filter"
    private const val KEY_SESSION_ACTIVE = "session_active"
    private const val KEY_SESSION_END = "session_end"

    private fun prefs(ctx: Context): SharedPreferences =
        ctx.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun scheduleJson(ctx: Context): String? =
        prefs(ctx).getString(KEY_SCHEDULE_JSON, null)

    fun setScheduleJson(ctx: Context, json: String) {
        prefs(ctx).edit().putString(KEY_SCHEDULE_JSON, json).apply()
    }

    /** Interruption filter to restore after silence; -1 = unknown. */
    fun savedFilter(ctx: Context): Int = prefs(ctx).getInt(KEY_SAVED_FILTER, -1)

    fun setSavedFilter(ctx: Context, filter: Int) {
        prefs(ctx).edit().putInt(KEY_SAVED_FILTER, filter).apply()
    }

    fun sessionActive(ctx: Context): Boolean =
        prefs(ctx).getBoolean(KEY_SESSION_ACTIVE, false)

    /** Epoch millis when the running silence session ends; -1 = none. */
    fun sessionEnd(ctx: Context): Long = prefs(ctx).getLong(KEY_SESSION_END, -1L)

    fun setSession(ctx: Context, active: Boolean, endMillis: Long) {
        prefs(ctx).edit()
            .putBoolean(KEY_SESSION_ACTIVE, active)
            .putLong(KEY_SESSION_END, endMillis)
            .apply()
    }
}
