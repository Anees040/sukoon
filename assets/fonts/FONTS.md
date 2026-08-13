# Urdu font — deliberate v0 decision

**v0 ships with NO bundled font (0 MB).** Urdu text renders in the system's
Naskh-style fallback (Noto Naskh/Nastaliq on most Androids). This is readable
everywhere and protects the 12–18 MB size budget.

The theme already sets `height: 1.9` line-height for Urdu text styles, which
is what Nastaliq needs — so bundling later is a pure asset swap.

## If you want true Nastaliq (نستعلیق) later

Noto Nastaliq Urdu is the gold standard, SIL Open Font License, ~1.1 MB for
the Regular weight.

1. Download from Google Fonts: <https://fonts.google.com/noto/specimen/Noto+Nastaliq+Urdu>
2. Copy **only** `NotoNastaliqUrdu-Regular.ttf` into this folder
   (skip Medium/SemiBold/Bold — each adds ~1 MB).
3. Copy `OFL.txt` from the download next to it (license requirement).
4. Uncomment the `fonts:` stanza at the bottom of `pubspec.yaml`.
5. In `lib/theme.dart`, set the Urdu `fontFamily` to `'NotoNastaliqUrdu'`
   (search for the `TODO-NASTALIQ` marker).
6. Verify: `flutter build appbundle --release` and check the size report
   stays under 25 MB (docs/skills/size_budget.md).

## Rules

- Never bundle more than Regular + one bold weight.
- Never bundle a Latin font — the default (Roboto) is fine and free.
- Test Urdu strings on a real device after bundling: Nastaliq is tall;
  clipped text = increase line-height, not font size.
