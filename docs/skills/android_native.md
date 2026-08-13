# SKILL: android_native — DND, alarms, receivers

## The contract (change = version bump both sides)

- Channels: `sukoon/dnd`, `sukoon/alarms` (MainActivity.kt registers both).
- Payload: versioned JSON (`version: 1`) stored in native prefs
  `sukoon_state` → key `schedule_json`. Kotlin receivers parse it with
  org.json — they have NO Flutter engine, so all notification strings are
  pre-localized by Dart inside the payload.
- Native prefs keys: `schedule_json`, `saved_filter`, `session_active`,
  `session_end`.

## Request-code map (PendingIntents — keep unique, keep stable)

| Range | Purpose |
|---|---|
| 1000+i | silence starts |
| 2000+i | ringer restores |
| 3000–3001 | masjid-mode start/end |
| 4000 | nightly qaza reminder |
| 6000+i | pre-azan heads-up |

## DND invariants (DndController.kt)

- Silence = `INTERRUPTION_FILTER_ALARMS`. Restore = the SAVED filter (or
  ALL if unknown).
- Save the user's current filter ONLY when `session_active == false` —
  overlapping sessions must not overwrite the true saved state.
- Restore is idempotent: checks `session_active` first; safe to call twice.
- Every enable sets `session_end`; BootReceiver clears stale sessions
  (boot after a crash mid-silence must restore the ringer).
- Notification channels: `silence_status` (LOW, ongoing, End-now action)
  and `reminders` (DEFAULT).

## Alarm invariants (PrayerAlarmScheduler.kt)

- `setExactAndAllowWhileIdle` for every start/end/pre-azan.
- API < 31 → `canScheduleExactAlarms` treated as true.
- Reschedule-all sources: syncSchedule call, BOOT_COMPLETED,
  TIMEZONE_CHANGED/TIME_SET. Always future-only from the stored JSON.
- Cancel by recreating the same PendingIntent (FLAG_IMMUTABLE) — request
  codes above must never drift.

## OEM reality (test matrix)

- **Tecno/Infinix (HiOS):** aggressive killer — battery exemption sheet is
  essential; also tell testers: Settings → Battery → App launch → Sukoon →
  Manage manually (allow all).
- **Xiaomi (MIUI):** Autostart permission + “No restrictions” battery.
- **Samsung:** remove from “Sleeping apps”.
Document tester-reported OEM quirks in PROJECT_STATE.md.

## adb cheatsheet (V-2)

```powershell
adb shell dumpsys notification_policy      # current filter
adb shell dumpsys alarm | Select-String sukoon   # scheduled alarms
adb shell am broadcast -a android.intent.action.BOOT_COMPLETED -p com.anees.sukoon  # boot sim (root/debug only)
adb logcat -s SukoonDnd SukoonAlarm        # receiver logs
```

## R8/minify

Release build minifies. Receivers/activities referenced from the manifest
are kept automatically, but if release-mode alarms fail while debug works:
check proguard-rules.pro keeps `com.anees.sukoon.**` receivers and org.json
usage intact before blaming anything else.
