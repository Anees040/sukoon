# SKILL: testing — the contract

## Policy (v0)

- Pure-Dart unit tests ONLY — no widget/golden/integration tests yet.
  Device behavior is verified by the V-2…V-6 human waves instead.
- The 7 suites in test/ are a CONTRACT. Numeric expectations were verified
  with an independent Python implementation (tool/verify_math.py).

## Iron rules

1. NEVER weaken, delete, or “adjust” a failing test to make it pass. A
   failing test means the Dart code is wrong. (Only exception: a test file
   with its own compile error — repair syntax, keep expected values.)
2. Every bug found on-device gets a regression test IF its logic is pure
   (math, payload, parsing). UI bugs get a V-wave checklist line instead.
3. New pure logic ⇒ new test file in the same style: group per function,
   test names state the rule in plain language.
4. Never import Flutter into pure-math files to “help” a test.

## Running

```powershell
flutter test                      # everything
flutter test test/qaza_estimator_test.dart   # one suite
```

## What each suite guards

| Suite | Guards |
|---|---|
| qaza_estimator_test | bulugh modes, hayd/nifas deductions, ceil rounding, witr toggle, never-negative |
| streak_test | 5/5 completeness, excused-day bridging, best-run, month stats denominators |
| plan_math_test | finish-date ceil, minutes/day honesty, plan streak walk-back |
| qibla_math_test | bearings for 4 PK cities (±2°), wrap-around, shortest-path rotation |
| schedule_payload_test | future-only filtering, sorting, end=start+window, JSON contract with Kotlin |
| cities_data_test | dataset size, unique ids, PK bounding box, bilingual names |
| arb_parity_test | EN↔UR key parity, placeholder parity, metadata sanity |

## Adding scenarios

Recompute expectations with `python tool/verify_math.py` (extend it in the
same commit) — never hand-derive numbers in your head, and never copy them
from the Dart implementation under test.
