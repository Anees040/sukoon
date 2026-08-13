# PROJECT_STATE — Sukoon (سکون) v0

> The agent MUST read this file at the start of every session and update it
> at the end of every wave. This is the single source of truth for progress.

**App:** Sukoon — auto-silent at prayer times + namaz tracker + qaza-e-umri + qibla + PK cities · EN/UR
**Package:** `com.anees.sukoon` · **Version:** 0.9.0+1 · **Budget:** 12–18 MB (cap 25)
**Gates:** Aug 23 (closed test live, ≥12 testers) · Sep 6 (production submitted)
**Generated:** v0 codebase written by Notion AI on Aug 11, 2026 — **never compiled**.
Expect real compile/analyze errors in V-1. That is normal and planned.

## Wave status

| Wave | Scope | Status |
|---|---|---|
| SS-0 setup | pubspec, l10n, lints, .gitignore, INSTALL | ✅ generated |
| SS-1 theme | Ember Night theme.dart, constants | ✅ generated |
| SS-2 shell | app shell, 5 tabs, locale switch | ✅ generated |
| SS-3 prayer times | adhan wrapper, home screen, countdown | ✅ generated |
| SS-4 silent engine (Dart) | schedule payload, channels, sync | ✅ generated |
| SS-5 silent engine (native) | Kotlin: DND, alarms, receivers, boot | ✅ generated |
| SS-6 permissions | primers, status card, battery sheet | ✅ generated |
| SS-7 tracker | log, streaks, heatmap, period mode | ✅ generated |
| SS-8 qaza wizard+estimator | 3 bulugh modes, female deductions | ✅ generated |
| SS-9 qaza dashboard+plan | ledger, repay, plan, reminder | ✅ generated |
| SS-10 achievements | 13 achievements, confetti wall | ✅ generated |
| SS-11 qibla | compass, sensors, calibration UX | ✅ generated |
| SS-12 cities | 100-city offline list, detail, favorites | ✅ generated |
| SS-13 polish+release | listing/privacy/release docs + brand PNGs generated; launcher icons & splash wiring happen locally | ⚠️ partial (finish in V-6) |
| Tests | 7 pure-Dart suites, math Python-verified | ✅ generated |
| V-1 compile-to-green | `pub get` → `analyze` → `test` all green | ✅ done (2026-08-13) · analyze 0 issues, 58 tests pass, release AAB builds |
| V-2 silent core on device | grant flows, azan silence, reboot | ⬜ pending |
| V-3 tracker+qaza on device | logging, wizard, plan, confetti | ⬜ pending |
| V-4 qibla+cities+notifs | compass, city times, reminders | ⬜ pending |
| V-5 Urdu/RTL audit | every screen in ur, COPY_REVIEW | ⬜ pending |
| V-6 release | icons, splash, keystore, aab, size | ⬜ pending |

## Decision log (v0 deviations from Master Plan — intentional)

1. **DND mechanism:** `INTERRUPTION_FILTER_ALARMS` + save/restore of the
   user's previous filter, instead of PRIORITY-policy mutation. Simpler and
   predictable on OEM skins. Revisit only if testers report media apps muted.
2. **Estimator formula:** deduct-first — `owed = ceil((gap − hayd − nifas) × (1 − prayedFraction))`.
   Deductions apply before the prayed-fraction (master plan §4 ordered it
   after). Deduct-first is more generous to the user and easier to defend;
   the explainer screen describes exactly this order.
3. **No bundled Urdu font (0 MB).** System fallback + `height: 1.9`.
   Upgrade path documented in assets/fonts/FONTS.md.
4. **Compass:** `sensors_plus` rotation-vector math instead of the
   flutter_qiblah package (one less transitive dependency; qibla_math.dart
   is ours and unit-tested).
5. **Streak rule:** excused (period) days count as COMPLETE for streaks and
   are excluded from month denominators — “your streak stays safe.”

## Known-unverified (check FIRST in V-1)

- `adhan` package API names in `lib/prayer/prayer_service.dart`
  (`CalculationMethod.karachi`, `Madhab.hanafi`, `PrayerTimes`,
  `Coordinates`) — verify against adhan ^2.0.0-nullsafety.2.
- `geolocator` v13 / `sensors_plus` v6 API shapes in `lib/core/location.dart`
  and `lib/qibla/compass_service.dart`.
- `flutter_animate` / `confetti` usage in qaza + tracker screens.
- gen-l10n output path `package:sukoon/l10n/gen/app_localizations.dart`
  (l10n.yaml uses synthetic-package: false).
- Kotlin notifications use `R.mipmap.ic_launcher` as small icon — exists
  after the `flutter create` overlay; confirm.

## V-wave fix log (append entries here)

<!--
Format:
### V-1 · 2026-08-1X
- file.dart: what was broken → what changed (1 line each)
- test results: X passed / Y failed → all green
-->

### V-1 · 2026-08-13 — compile-to-green
`flutter analyze`: 18 issues (7 errors, 4 warnings, 7 infos) → **0**.
`flutter test`: 37 passing with 2 suites failing to load → **58 passing, 0 failing**.

Errors:
- lib/data/prayer_log_repository.dart: `ConflictAlgorithm` unresolved → added the
  missing `package:sqflite/sqflite.dart` import (blocked streak_test from loading).
- lib/qaza/qaza_estimator.dart: `library;` sat after the imports → moved the
  directive + its doc comment above them (blocked qaza_estimator_test from loading).
- lib/core/location.dart: **file was missing entirely** (imported by app_shell +
  settings_screen) → written against the real geolocator 13.0.4 API
  (`LocationSettings`, `LocationPermission`), coarse accuracy, 10 s limit,
  `getLastKnownPosition()` fallback, every failure path returns false.
- lib/l10n/app_en.arb + app_ur.arb: `masjidNeedAccess` used by home_screen but
  defined in neither file → added to both (parity test enforces this).

Warnings/infos:
- wizard.dart, primers.dart: dropped unused `constants.dart` imports.
- wizard.dart: removed unused `t` (textTheme).
- compass_service.dart: removed unused `ayn` — only My is needed for azimuth.
- planner.dart: `n == null ? null : n.clamp(...)` → `n?.clamp(...)`.
- prayer_log_repository.dart: two double-quoted SQL strings → single quotes.
- dashboard.dart: `mounted` re-check after the `_reload()` gap before the snackbar.
- settings_screen.dart: GPS button captures `ScaffoldMessenger` before the await;
  the language switch now delegates to `_sync()` (identical semantics, and it
  reads `AppLocalizations` *after* the locale flips, so the native side gets the
  new locale's strings).

Decisions taken during the fix (flagged for review):
6. **GPS is opt-in, not asked at bootstrap.** `LocationService.refresh({silent})`
   — app_shell passes `silent: true` so a location dialog never stacks on top of
   the first-run DND primer; the prompt happens only on Settings → "Use GPS".
7. **Nearest-city labelling, no reverse geocoding.** A coarse fix is labelled
   with the closest city in pk_cities.json (`nameEn`, matching city_detail.dart);
   prayer times still use the raw lat/lng. Keeps the no-network rule intact.

Still open (NOT fixed — outside compile-to-green):
- `Prefs.locationLabel` stores an English city name, so the location chip shows
  English text in Urdu UI. Pre-existing (city_detail.dart:25); belongs to V-5.
- CLAUDE.md's size-check command needs `--target-platform android-arm64`;
  `--analyze-size` refuses a multi-ABI appbundle.
- `masjidNeedAccess` Urdu was assembled from already-vetted phrases in
  app_ur.arb; worth an eyeball during the V-5 Urdu audit.
- Gradle prints `target value 8 is obsolete` (×3). Java 8 target in
  android/app/build.gradle — harmless today, will break on a future AGP.

**Size baseline (first measurement — no delta yet).** arm64-only release AAB,
`flutter build appbundle --release --analyze-size --target-platform android-arm64`:

| Slice | Size |
|---|---|
| **app-release.aab total** | **15.6 MB** |
| ├ debug symbols (NOT in the user download) | 6 MB |
| ├ base/lib (native, arm64) | 8 MB |
| ├ base/dex | 555 KB |
| ├ base/assets (pk_cities.json + brand) | 120 KB |
| └ package:sukoon (our Dart) | 230 KB |

Within the 12–18 MB budget. The Play download is well under the 25 MB cap: the
6 MB of debug symbols never ships, and Play serves one ABI per device. Compare
future waves against **15.6 MB** using the same single-ABI command.

Also verified by this build: **the Kotlin/native side compiles** (MainActivity,
NativeState, DndController, PrayerAlarmScheduler + all five receivers) — it had
never been through a Gradle build before. Runtime behaviour is still V-2's job.

