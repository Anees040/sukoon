# Sukoon — project guide for Claude Code

## What this app is
Sukoon (سکون) — an Android-only Flutter app for Pakistani Muslims, English + Urdu. Modules: (1) auto-silent: DND at each prayer time, restore ringer after 15/20/30 min, plus one-tap Masjid Mode; (2) offline prayer times + ~100 Pakistani cities; (3) daily namaz tracker (streaks, heatmap, period mode); (4) qaza-e-umri calculator, editable ledger, repayment planner, achievements; (5) qibla compass; (6) full EN/UR localization. Solo ship project by Muhammad Anees. Gates: closed test live Aug 23; production submitted Sep 6, 2026. Scope is FROZEN — NO Quran text, NO Hadith text, NO azan audio, no tasbih, no hijri calendar, no maps, no accounts, no ads, no backend, no iOS.

## Where this code came from — READ FIRST
This codebase is a **v0 draft written by another AI without a Flutter SDK or device**. It is architecturally deliberate but unverified. Your job in the first sessions is **verify and fix (docs/VERIFY_PLAN.md)**, not rebuild:
- Treat the compiler and tests as the source of truth for *correctness*, and this file + `docs/PROJECT_STATE.md` as the source of truth for *design intent*.
- When `flutter analyze` flags an error, make the smallest fix that preserves the stated design. Do NOT swap architecture (e.g. do not replace native receivers with flutter_local_notifications) to silence an error.
- If a package API changed vs what the code assumes, adapt the call sites; do not fork the design.
- Log every meaningful fix in `docs/PROJECT_STATE.md` under "V-wave fix log".

## Stack
- Flutter 3.35.x. Dart owns UI, adhan prayer math (CalculationMethod karachi default, Madhab.hanafi Asr default), sqflite history, l10n.
- Native Kotlin owns everything that must run with the app killed: DND control, AlarmManager exact alarms, receivers (prayer-start, restore-ringer, reminder, boot, timezone). MethodChannels "sukoon/dnd" and "sukoon/alarms".
- DND DESIGN DECISION: we use `setInterruptionFilter(INTERRUPTION_FILTER_ALARMS)` (alarms-only DND level) and save/restore the user's previous filter — we never modify the user's notification policy. Alarms still ring; calls/notifications are silenced.
- State: shared_preferences (settings) · native SharedPreferences "sukoon_state" (schedule + strings JSON — receivers never need the Flutter engine) · sqflite sukoon.db (tracker + qaza; schemaVersion constant in lib/data/db.dart).
- applicationId com.anees.sukoon. No network calls anywhere. No Firebase.

## Commands (Windows PowerShell — chain with ; never &&)
- flutter pub get · flutter gen-l10n · flutter analyze · flutter test
- Run: flutter run -d <device-id>  (physical Tecno Pova 2 — emulator cannot grant DND access)
- Size check (end of EVERY wave): flutter build appbundle --release --analyze-size — report size + delta vs last wave.

## Layout
- lib/constants.dart (ALL identifiers/keys) · lib/theme.dart (Ember Night tokens)
- lib/l10n/ app_en.arb + app_ur.arb (generated code in lib/l10n/gen/, gitignored)
- lib/core/ prefs.dart, locale_controller.dart
- lib/prayer/ prayer_service.dart (adhan wrapper), schedule_payload.dart (pure, tested)
- lib/native/ dnd_channel.dart, alarms_channel.dart, schedule_sync.dart
- lib/data/ db.dart, prayer_log_repository.dart, qaza_repository.dart, achievements.dart
- lib/qaza/qaza_estimator.dart (pure, tested) · lib/qibla/ qibla_math.dart (pure, tested), compass_service.dart
- lib/features/{shell,home,tracker,qaza,qibla,cities,settings,common}
- android/app/src/main/kotlin/com/anees/sukoon/ — MainActivity, NativeState, DndController, PrayerAlarmScheduler, PrayerAlarmReceiver, RestoreRingerReceiver, ReminderReceiver, BootReceiver, TimezoneChangedReceiver
- assets/data/pk_cities.json · assets/brand/ (icons) · docs/ (specs, skills, release)

## Hard rules
- NEVER crash on a denied permission: guard exact alarms with canScheduleExactAlarms(), DND with isNotificationPolicyAccessGranted(), notifications with POST_NOTIFICATIONS state; on denial show the primer/banner and do nothing else.
- NEVER use USE_EXACT_ALARM — SCHEDULE_EXACT_ALARM with the runtime request flow only.
- DND: save the CURRENT interruption filter before silencing; restore exactly that filter; never touch NotificationPolicy; guard overlapping sessions with the session_active flag.
- All timing lives in Kotlin receivers reading native prefs — Dart never schedules or fires anything time-based. No foreground services, no polling timers, no flutter_local_notifications.
- LOCALIZATION: every user-facing string goes through AppLocalizations, keys added to BOTH app_en.arb and app_ur.arb in the same change. Simple everyday Pakistani Urdu (namaz not salat; فجر/ظہر/عصر/مغرب/عشاء/وتر). Flag uncertain Urdu with TODO-URDU-REVIEW in the @description, never in the string. Hardcoded UI strings are a bug.
- RELIGIOUS COPY: NEVER quote or paraphrase Quran or Hadith anywhere, including motivation strings. No fatwa-style language. Qaza numbers are always "estimates" + "confirm with your local scholar". Gentle, private tone — never shaming. Full rules: docs/skills/fiqh_copy_rules.md.
- SIZE: no binary asset >50 KB without asking; no Lottie/Rive/GIF/audio/video ever — animations are code-driven (flutter_animate, confetti, CustomPainter). New packages need a one-line size justification. Hard cap: 25 MB Play download.
- THEME: all colors/text styles from lib/theme.dart tokens — no raw Color/TextStyle literals in feature code. Ember Night: near-black surfaces, accent #FF8A4C, lime #D3F158, NO blue, no gradients. Urdu line-height ≥ 1.8.
- sqflite schema changes: bump schemaVersion + hand-written migration + upgrade-path test. Never delete/skip/weaken a failing test to look green.
- One commit per wave; never git push unless asked.

## Wave protocol
Muhammad pastes one prompt at a time from docs/VERIFY_PLAN.md (SUK-0, V-1..V-6), and later review-fix prompts:
1. Short plan first (files, order). Wait for OK.
2. Implement smallest-change fixes. If code contradicts a spec assumption, say so and adapt — acceptance criteria stand.
3. Run flutter analyze + flutter test; fix until clean. Run the size check and report it.
4. Print a short manual phone test script for the wave.
5. git add -A; git commit -m "V-x: <summary>". Stay strictly inside the wave's scope.

## Review-fix loop (after V-waves)
Muhammad tests on his Tecno and pastes a structured review (docs/REVIEW_TEMPLATE.md). For each item: reproduce reasoning → smallest fix → regression test if logic-level → report. Never fix items outside the pasted review in the same commit.
