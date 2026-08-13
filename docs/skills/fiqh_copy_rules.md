# SKILL: fiqh_copy_rules — how this app talks about worship

Sukoon touches people's worship. The copy must be humble, precise, and
never pretend to authority it doesn't have. These rules bind EVERY string.

## The five laws

1. **Estimates, never verdicts.** Every qaza number is “an estimate to help
   you start”. Words like “you owe exactly”, “Islam says”, “fatwa” are
   banned from UI copy. The disclaimer (wizDisclaimer/aboutDisclaimer)
   appears before saving the ledger and in About — never remove or bury it.
2. **No Quran or Hadith text in-app.** Not even one ayah. (Rendering the
   Quran brings adab + accuracy obligations this app deliberately avoids.)
   Referencing concepts (qaza, bulugh, witr) is fine; quoting scripture is not.
3. **No shame mechanics.** Missed prayers are logged in neutral red, never
   with guilt copy (“you failed”, streak-loss drama, crying emoji). The
   tone for missed/qaza: “start where you are”. Excused days phrasing:
   dignity first (“your streak stays safe”).
4. **Madhhab honesty.** Defaults are Hanafi (Asr, witr-in-qaza) because the
   audience is Pakistan — SAY SO where it matters (wizWitrHint, settings
   method labels) and keep the toggle. Never present a Hanafi default as
   universal law; never argue madhhab in copy.
5. **Worship isn't a game.** Achievements celebrate consistency and
   completion (“100 repaid”, “30-day plan streak”) — they never promise
   reward from Allah, never rank users, never use casino language
   (“jackpot”, “level up”). Confetti ≤ once per unlock.

## Sensitive areas

- **Hayd/nifas wizard steps:** clinical-gentle wording, privacy reassurance
  (wizFemaleHint), no euphemism soup — clear terms, respectful register in
  Urdu (معذوری کا دن / ایام). Any change here goes to COPY_REVIEW.md.
- **Bulugh questions:** frame as “when did prayer become obligatory for
  you”, offer “I don't remember” → deemed mode. Never ask for medical detail
  beyond the fiqh-relevant numbers.
- **Prayer names:** transliterations used by Pakistani users (Fajr, Zuhr,
  Asr, Maghrib, Isha, Witr) — not Dhuhr/Esha — consistent everywhere.

## Process

- Any new/changed string touching worship → add a row to docs/COPY_REVIEW.md
  with both languages + concern; flag `TODO-URDU-REVIEW` in the ARB
  @description until a human signs off.
- Scholar review before production (Gate 2) is a release blocker — the
  review log table in COPY_REVIEW.md must have at least one signed row.
