# VERIFY_PLAN — from generated v0 to shippable app

The SS-prompts on the Notion playbook remain the **spec**. This file is the
**execution path** now that a v0 codebase exists: paste each prompt below
into Claude Code (repo root), one wave at a time — same discipline as
FitPilot. After every wave: commit, update docs/PROJECT_STATE.md.

---

## SUK-0 — kickoff audit (no fixes yet)

```
Read CLAUDE.md, docs/PROJECT_STATE.md, and every file in docs/skills/.
Then, WITHOUT changing any code:
1. Run: flutter pub get
2. Run: flutter gen-l10n
3. Run: flutter analyze
4. Run: flutter test
5. Compare the file tree against INSTALL.md's expected layout; list anything
   missing or extra.
6. Group every error by file, with the likely root cause (wrong package API,
   typo, missing import, bad type). Check the "Known-unverified" list in
   PROJECT_STATE.md first — those are the most likely error sources.
Output: a numbered V-1 fix plan ordered so foundational files (constants,
theme, prefs, l10n) are fixed before screens. Do not fix anything yet.
```

**Pass:** full inventory + grouped error list + ordered fix plan.

---

## V-1 — compile-analyze-test to green

```
Execute the V-1 fix plan from SUK-0. Rules:
- Work in order; re-run flutter analyze after each file.
- NEVER weaken or delete a test to make it pass. The numeric expectations in
  test/ were verified with an independent Python implementation — if a test
  fails, the Dart code is wrong. Only a test with its own compile error may
  be repaired, without changing expected values.
- NEVER rename prayer keys ('fajr','zuhr','asr','maghrib','isha','witr'),
  MethodChannel names (sukoon/dnd, sukoon/alarms), payload JSON keys, or
  SharedPreferences keys — the Kotlin side depends on them verbatim.
- If adhan/geolocator/sensors_plus APIs differ from the code, adapt ONLY the
  wrapper files (prayer_service.dart, location.dart, compass_service.dart).
- If the AppLocalizations import path differs, fix the import in
  l10n_ext.dart — do not restructure l10n.yaml.
Finish line: flutter analyze → 0 issues; flutter test → all green;
flutter run shows the Home screen.
Append a V-1 entry to the PROJECT_STATE.md fix log (1 line per fix).
```

**Pass:** analyze 0 issues · all tests green · app boots to Home.

---

## V-2 — silent core on a real device (the heart)

```
Goal: prove the auto-silent loop end to end on my phone (Tecno Pova 2).
Guide me interactively:
1. flutter run --release on the connected device.
2. Onboarding primer → grant DND access, exact alarms, notifications,
   battery exemption. Permission status card must show all green.
3. Set silence window 15 min. Home countdown matches my city's next prayer.
4. Masjid mode: start manual silence → DND icon appears → ongoing
   notification with End-now → tap it → ringer restores immediately.
5. Real azan test: wait for the next prayer (or set device clock to 2 min
   before azan) → phone silences at azan → restores after the window.
6. Reboot after scheduling AND mid-silence → alarms survive; a stale
   session cleans up (ringer not stuck on silent).
7. Repeat one azan test with battery saver ON (HiOS is aggressive — see
   docs/skills/android_native.md).
Log every deviation in PROJECT_STATE.md; fix and re-test. Do not move to
V-3 until steps 4–6 all pass.
```

**Pass:** azan → silent → auto-restore · reboot-safe · End-now works.

---

## V-3 — tracker + qaza flows on device

```
Walk me through on-device, fixing anything broken:
1. Tracker: tap-cycle each prayer (none→prayed→jama'at→missed→none),
   heatmap updates, streak increments at 5/5, period-day toggle keeps the
   streak safe and recolors the day.
2. Qaza wizard: run all three bulugh modes; the female path shows hayd/nifas
   steps; S1 inputs (male, bulugh 2010-01-01, regular since 2020-01-01, 0%)
   → exactly 3652 per prayer.
3. Explainer screen shows the step-by-step calculation with my real numbers.
4. Edit-and-confirm: change one number before saving — ledger honors it.
5. Repay: +1 / +5 / +today's-plan, undo restores, progress ring animates.
6. Plan: 5 sets/day → finish date = ceil(remaining/5) days ahead; honest
   minutes/day figure matches settings.
7. Achievements: unlock first_qaza → confetti fires once; wall shows it
   unlocked, others locked.
8. Nightly reminder: set 2 minutes ahead → notification fires.
```

**Pass:** all 8 green on device.

---

## V-4 — qibla + cities + notification polish

```
1. Qibla: needle rotates smoothly (no 359→0 spin), aligned state (±3°)
   turns accent + haptic; calibration hint appears when the sensor is noisy
   (wave the phone near metal); no-sensor fallback shows the static bearing
   with city name.
2. Cities: search in English AND Urdu script; favorites pin to top and
   persist; city detail shows today's 5 times + tomorrow's fajr; "use as my
   location" updates Home + re-syncs the silence schedule.
3. Pre-azan notification (set 10 min) fires before the next prayer.
4. All notification texts render correctly in both languages (switch locale
   between tests).
```

**Pass:** compass trustworthy · cities offline · both notification types fire.

---

## V-5 — Urdu / RTL audit

```
Switch the app to Urdu and audit EVERY screen against docs/skills/urdu_l10n.md:
1. Layout mirrors correctly (back buttons, chevrons, sliders, heatmap grid).
2. No clipped/overlapping Urdu text (line height 1.9 must hold everywhere).
3. Numbers: Western digits everywhere (v0 policy), dates localized.
4. Every user-visible string comes from ARB — grep for hardcoded literals in
   lib/features/ and fix any stragglers.
5. Cross-check the 6 strings flagged TODO-URDU-REVIEW in app_en.arb against
   docs/COPY_REVIEW.md wording.
Produce a list of any strings still needing a human Urdu proofread.
```

**Pass:** full RTL pass + zero hardcoded strings + review list for Anees.

---

## V-6 — release build, size, Play readiness

```
1. Add flutter_launcher_icons + flutter_native_splash as dev deps (configs
   already in pubspec.yaml, images in assets/brand/) → run both generators.
2. Create the keystore per docs/PLAY_RELEASE.md (alias sukoon), fill
   android/key.properties (never commit it — .gitignore already covers it).
3. flutter build appbundle --release --analyze-size → record the size
   breakdown in PROJECT_STATE.md. Budget: 12–18 MB, hard cap 25 MB. If over:
   docs/skills/size_budget.md checklist.
4. Install the release build from the bundle (bundletool or Play internal
   testing) — verify DND + alarms still work under R8/minify (the Kotlin
   receivers must not be stripped; check android/app/proguard-rules.pro).
5. Walk me through docs/PLAY_RELEASE.md: closed-testing track, 12 testers,
   data-safety form answers, DND permission declaration.
```

**Pass:** signed aab ≤ 25 MB · release build passes a V-2 smoke test · uploaded.

---

## Standing rules for every wave

- One wave per session; never mix waves.
- Re-run `flutter test` before every commit — the suites are the contract.
- Update PROJECT_STATE.md status table + fix log every session.
- Any fiqh-touching copy change must follow docs/skills/fiqh_copy_rules.md
  and be added to docs/COPY_REVIEW.md.
