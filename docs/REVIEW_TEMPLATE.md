# REVIEW_TEMPLATE — paste one per testing round

Copy this template, fill it on your phone while testing, then paste the
whole thing back to Notion AI (or Claude Code). Structured reviews turn
directly into fix prompts — vague ones don't.

```markdown
## Sukoon review — round N · <date>

**Build:** 0.9.0+1 (or whatever About shows)
**Device:** Tecno Pova 2 · Android <version> · HiOS <version>
**Language tested:** EN / UR / both
**Battery saver on?** yes/no

### Blockers (app unusable / crash / silent failed)
1. Screen → Steps to reproduce → What happened → What I expected
   (attach screenshot name if any)

### Bugs (wrong behavior, not blocking)
1. …

### Silent-core log (fill for EVERY azan you observed)
| Prayer | Azan time | Silenced? (on time / late / no) | Restored? (on time / late / no) | Notes |
|---|---|---|---|---|
| Fajr | 04:32 | … | … | … |

### UI/UX (looks wrong, awkward, Urdu issues)
1. Screen → what looks wrong → screenshot name

### Copy/fiqh concerns
1. Exact string → where seen → concern

### Ideas (park for later — do NOT act this round)
1. …

### Verdict
- [ ] Ready for the 12 testers
- [ ] One more fix round needed
```

## Severity rules

- **Blocker:** crash, silent-core miss (didn't silence or didn't restore),
  data loss (ledger/tracker reset), stuck-on-silent after End-now.
- **Bug:** wrong number, wrong time, broken navigation, notification missing.
- **UI/UX:** everything visual, including Urdu clipping and RTL mirroring.
- Deviations in qaza math are **Blockers** — the numbers are the product.

## What happens with your review

1. Notion AI analyzes the filled template.
2. You get back: root-cause guesses + a numbered set of paste-ready fix
   prompts for Claude Code (F-1, F-2, …), ordered by severity.
3. Run them one at a time, re-test only the affected flows, commit each fix.
4. Repeat until the Verdict box flips.
