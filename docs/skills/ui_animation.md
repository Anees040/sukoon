# SKILL: ui_animation — motion rules

Motion sells the app in 10 seconds of Play-Store video — but only when it's
fast and purposeful. Sluggish = uninstall.

## Timing

- Micro feedback (taps, toggles): 120–180 ms, `Curves.easeOutCubic`.
- State/content transitions: 200–300 ms.
- Celebrations (confetti, ring fill on big milestones): ≤ 1200 ms, once.
- NEVER animate longer than 300 ms on the critical path (log a prayer,
  toggle silence).

## Patterns in this codebase

- `flutter_animate`: entrance staggers —
  `.animate().fadeIn(duration: 200.ms).slideY(begin: .06)`; stagger list
  children by 40–60 ms; never stagger more than 6 items.
- `AnimatedSwitcher` for value swaps (countdown numbers, status chips) with
  `FadeTransition` + tiny slide; key by value.
- `ProgressRing` uses `TweenAnimationBuilder` — rings animate to the new
  value, 400–600 ms, easeOutCubic — never jump.
- `CountUpText` for numeric stats — don't reimplement counting.
- Confetti (`confetti` package): ONLY on achievement unlock and plan-finish
  projection reached. One burst, 800 ms, from the top of the card. Never on
  routine repay taps.
- Qibla needle: rotate via `angleDelta()` shortest path, EMA-smoothed — no
  spring physics, no overshoot beyond 2°.
- Heatmap day fill: 150 ms color tween on log change.

## Reduce motion

Respect `MediaQuery.disableAnimations` — when true: skip entrance staggers
and confetti entirely (guard exists in helpers; keep it when adding motion).

## Jank rules

- `const` constructors everywhere possible; extract stateless subtrees.
- No `Opacity` widget in animations — use `FadeTransition`/`.fadeIn`.
- Never rebuild the whole screen for a ticking countdown — the timer
  rebuilds only the countdown `Text` (see home_screen's `_Countdown`).
- Test on the Tecno Pova 2 (low-end) — if it stutters there, simplify.
