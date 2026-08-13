# COPY_REVIEW — religious copy that needs human review

Every string that touches fiqh, worship, or women's excused days must pass
two reviews before production (Gate 2, Sep 6):

1. **Urdu proofread** — any educated native speaker.
2. **Scholar sanity-check** — your local imam/mufti reads the English or
   Urdu column and confirms the wording is acceptable. Log name + date.

Rules the copy already follows (keep it that way — docs/skills/fiqh_copy_rules.md):
estimates never presented as verdicts · no Quran/Hadith text anywhere in the
app · no shame language for missed prayers · madhhab named only where it
matters (Hanafi Asr, witr default).

## Flagged strings (TODO-URDU-REVIEW in app_en.arb)

| # | ARB key | English (as shipped) | Urdu (as shipped) | Concern | Scholar OK? |
|---|---|---|---|---|---|
| 1 | aboutDisclaimer | Sukoon gives estimates and reminders, not religious rulings. For your specific situation, please consult your local scholar. | سکون اندازے اور یاددہانیاں فراہم کرتا ہے، شرعی فتویٰ نہیں۔ اپنی مخصوص صورتحال کے لیے اپنے مقامی عالم سے رجوع کریں۔ | Must read as humble utility, not fatwa service | ⬜ |
| 2 | trackerPeriodDay | Excused day | معذوری کا دن | Respectful term for menstruation day — is معذوری the best word, or ایام؟ | ⬜ |
| 3 | wizBulughQ | When did daily prayers become obligatory for you (bulugh)? | آپ پر نماز کب فرض ہوئی (بلوغ)؟ | Correct framing of bulugh for both genders | ⬜ |
| 4 | wizFemaleHint | These questions help estimate days when prayer was not obligatory. Your answers stay on this phone. | یہ سوالات ان دنوں کا اندازہ لگانے میں مدد دیتے ہیں جب نماز فرض نہیں تھی۔ آپ کے جوابات اسی فون پر رہتے ہیں۔ | Dignity + privacy reassurance for hayd/nifas questions | ⬜ |
| 5 | wizWitrHint | Hanafi practice counts Witr as obligatory to make up. You can turn this off. | حنفی مسلک میں وتر کی قضا بھی لازم ہے۔ آپ اسے بند کر سکتے ہیں۔ | Accurate one-line Hanafi witr statement | ⬜ |
| 6 | wizDisclaimer | This is an estimate to help you start, not a ruling. Adjust the numbers if you know better, and confirm with your local scholar. | یہ محض ایک اندازہ ہے تاکہ آپ آغاز کر سکیں، شرعی حکم نہیں۔ اگر آپ بہتر جانتے ہیں تو اعداد خود درست کریں، اور اپنے مقامی عالم سے تصدیق کریں۔ | The load-bearing disclaimer — shown before saving the ledger | ⬜ |

## Second-priority strings (review with the same pass)

| ARB key | English | Why listed |
|---|---|---|
| wizModeDeemed / wizModeCautious / wizModeRemembered | the three bulugh mode labels + their one-line explanations | fiqh accuracy |
| explainer* (all keys starting `explainer`) | step-by-step calculation wording | must match what the code actually does |
| qazaPlanFinish | “At this pace you finish around {date}” | promise wording — keep “around” |
| achievement titles (achFirst … achPct100) | milestone names | encouragement, not worship-gamification |
| notifSilenceTitle/Body, notifRestoreTitle/Body | DND notifications | tone check |
| homeAutoSilenceAt | “Auto-silence at {time} · {minutes} min” | clarity |

## Review log

| Date | Reviewer | Role | Result / changes requested |
|---|---|---|---|
| — | — | — | — |

## How to change a string after review

1. Edit `lib/l10n/app_en.arb` and/or `app_ur.arb` (keep placeholders identical).
2. `flutter gen-l10n && flutter test` (arb_parity_test guards you).
3. Update the table above and commit with message `copy: <key> per review`.
