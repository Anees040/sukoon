# SKILL: flutter_dev — project conventions

## Architecture (keep it boring)

- Plain `StatefulWidget` + `setState`. NO riverpod/bloc/provider — do not add.
- Cross-screen refresh: bump `Prefs.revision` (a `ValueNotifier<int>`);
  screens listen and reload. That's the whole state system.
- Wrapper layers — the ONLY files allowed to touch their package:
  - `lib/prayer/prayer_service.dart` → adhan
  - `lib/core/location.dart` → geolocator
  - `lib/qibla/compass_service.dart` → sensors_plus
  - `lib/core/prefs.dart` → shared_preferences
  - `lib/data/db.dart` → sqflite
- Pure-math files must stay Flutter-free (they are unit-tested):
  qaza_estimator, plan_math, qibla_math, streak, schedule_payload, dates.

## Hard invariants (Kotlin depends on these verbatim)

- Prayer keys: `fajr zuhr asr maghrib isha witr` — never rename, never
  translate in data. Display names come from l10n via `prayerName()`.
- Channels: `sukoon/dnd`, `sukoon/alarms`. Payload JSON keys are versioned
  (`version: 1`) — changing any key requires bumping the version AND
  updating the Kotlin receivers in the same commit.
- `dateKey()` format `yyyy-MM-dd` is a storage format — NEVER localize.
- After ANY change to prayers/settings that affects scheduling, call
  `ScheduleSync.push(l10n)` — grep for existing call sites to copy the pattern.

## Dependencies

- Adding a package needs a reason + size check (docs/skills/size_budget.md).
  Run `flutter build appbundle --analyze-size` before and after.
- Pinned majors in pubspec — do not bump majors during V-waves.

## Style

- `flutter_lints` 5 is the law; `flutter analyze` must stay at 0.
- Imports: `package:sukoon/...` absolute, never relative `../`.
- All user-visible strings via `context.l10n.<key>` — zero hardcoded UI text.
- Async in widgets: guard every `setState` with `if (!mounted) return;`.
- DB access only through the two repositories; no raw SQL in screens.

## When something looks wrong

- Suspect the wrapper first, the pure math last (it's Python-verified).
- Fix compile errors bottom-up: constants → core → data → features.
