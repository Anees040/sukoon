# SKILL: design_system — Ember Night

Dark-only. One accent. No blue. No gradients. If a screen looks like a
generic Material demo, it's wrong.

## Tokens (lib/theme.dart is the source of truth)

| Token | Hex | Use |
|---|---|---|
| bg | #0F0F0F | scaffold |
| surface | #1A1A1A | app bars, sheets |
| card | #232323 | SectionCard default |
| cardRaised | #2C2C2C | pressed/hover, chips |
| stroke | #3A3A3A | 1px borders, dividers |
| accent | #FF8A4C | THE ember — primary actions, active states, aligned qibla |
| accentDim | #7A4326 | accent's muted sibling (rings' track, secondary highlight) |
| lime | #D3F158 | success/streak moments ONLY (sparingly!) |
| limeDim | #5F6E28 | lime's track |
| text | #F3EFE7 | primary text |
| textSecondary | #A09A8E | labels, captions |
| textFaint | #6E6A61 | disabled, placeholders |
| danger | #FF6B6B | missed, destructive |
| warning | #FFC24C | permission warnings |

Heatmap fill steps: card → #3D2A1C → #5C3A22 → #8A4E28 → #C26B35 → accent.

## Rules

- Radius: 16 everywhere (`kRadius`). Screen padding: `kScreenPad`
  LTRB(16, 8, 16, 24). Gaps: multiples of 4; section gap 16–24.
- Type scale: title 22/w700 · section 17/w600 · body 15 · caption 13
  · numerals in stats use tabular figures (`FontFeature.tabularFigures()`).
- Urdu line-height 1.9; English 1.25. Never shrink Urdu below 15.
- Touch targets ≥ 48dp. Prayer-log tap cycle must be one-handed friendly.
- Icons: Material rounded set, 1.5px optical weight, textSecondary at rest,
  accent when active.
- Accent discipline: max ONE accent-colored primary element per viewport;
  lime appears only on completion moments (streak day, plan done, unlock).
- Empty states: use `EmptyState` widget — icon, one warm sentence, one action.
- Motion: see ui_animation.md. Elevation: none — depth comes from surface
  steps and strokes, not shadows.

## Components (lib/features/common/widgets.dart)

- `SectionCard` — the base container; don't hand-roll Containers in screens.
- `ProgressRing` — qaza progress; accent on accentDim track.
- `CountUpText` — animated numerals for stats.
- Add new shared components to widgets.dart, styled from tokens only.
