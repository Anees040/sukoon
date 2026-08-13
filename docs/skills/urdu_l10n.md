# SKILL: urdu_l10n — bilingual + RTL rules

## Pipeline

- Source of truth: `lib/l10n/app_en.arb` (template, with placeholder
  metadata) + `lib/l10n/app_ur.arb` (values only + @@locale).
- `flutter gen-l10n` → `lib/l10n/gen/` → use via `context.l10n.<key>`
  (extension in core/l10n_ext.dart).
- `arb_parity_test` enforces key + placeholder parity — run it after every
  string change.

## Key naming

`<area><Thing>` camelCase: homeNextPrayer, wizBulughQ, qazaRepaidAction,
trackerPeriodDay, achPct100… Never reuse a key for a different meaning;
add a new key instead.

## String rules

- Zero hardcoded user-visible strings in lib/features/ — grep before commit:
  `grep -rn "Text('" lib/features --include=*.dart` should return only
  non-UI literals (keys, debug). Everything else → ARB.
- Prayer display names ONLY via `prayerName(l10n, key)`.
- Placeholders: same names in both files; int placeholders typed int in
  metadata. Never concatenate translated fragments — use placeholders.
- Fiqh-touching strings: follow docs/skills/fiqh_copy_rules.md + add to
  docs/COPY_REVIEW.md. Six strings are flagged TODO-URDU-REVIEW in the ARB
  @descriptions — don't reword them casually.
- Digits: Western (0-9) everywhere in v0, both locales. Dates through
  `formatShortDate`/`formatTime` (intl, locale-aware).

## RTL rules

- NEVER use EdgeInsets.only(left/right) or Alignment.centerLeft/Right in
  screens — use EdgeInsetsDirectional / AlignmentDirectional / start-end.
- Icons that imply direction (chevrons, back, arrows) must flip: prefer
  directional icons (chevron_forward with auto-mirroring) or wrap custom
  arrows in a Directionality-aware rotation.
- The heatmap grid, week rows, and the qibla dial are intentionally
  LTR-fixed (calendar/compass semantics) — wrapped in
  `Directionality(textDirection: TextDirection.ltr)`. Keep them that way;
  their labels still localize.
- Urdu text style: height 1.9 (already in theme). If Urdu clips vertically,
  fix line height/padding — never shrink the font below 15.
- Test every screen in BOTH locales before calling a wave done (V-5 audits
  all of it).

## Locale switching

`LocaleController` (core/locale_controller.dart): system / en / ur. The
in-app language toggle lives in Settings — and re-pushes the native
schedule payload (notification strings are baked per-locale) via
`ScheduleSync.push(l10n)`. Any new notification string must flow through
the payload, not Kotlin resources.
