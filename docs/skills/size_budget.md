# SKILL: size_budget — 12–18 MB, hard cap 25

FitPilot ballooned to 220 MB. Sukoon must not. Budget: **12–18 MB** download
size per ABI, **hard cap 25 MB**. Check at every release build.

## Measure

```powershell
flutter build appbundle --release --analyze-size
```

Record the summary in PROJECT_STATE.md each V-6 run. For the true Play
download size, check Play Console → App bundle explorer after upload
(AAB splits per device — the per-ABI download is what users feel).

## Standing rules

- **Assets:** no single asset > 50 KB without written justification in
  PROJECT_STATE.md. Icons/splash PNGs are generated per-density by the
  tooling — don't ship the 1024px masters in assets/ that get bundled
  (assets/brand/ is EXCLUDED from pubspec assets on purpose; only
  pk_cities.json and fonts/ are bundled).
- **Fonts:** 0 bundled fonts in v0 (system fallback). If Nastaliq is added:
  Regular weight only (~1.1 MB) — see assets/fonts/FONTS.md.
- **Packages:** every new dependency = size check before merge. Prefer
  pure-Dart. Reject anything that drags in ffmpeg/exoplayer/maps/webview.
- **Images in UI:** none. The design is vector-by-code (shapes, icons).
  Illustrations = CustomPaint or nothing.
- **Tree-shaking:** release builds tree-shake Material icons automatically
  (expect the “MaterialIcons-Regular.otf reduced” line — if it disappears,
  someone used dynamic icon lookups; fix that).
- **Native:** minify+shrinkResources stay ON for release (already set).
  Never add `android:extractNativeLibs="true"`.

## If over budget — checklist, in order

1. `--analyze-size` → open the largest offenders list.
2. Check assets/ for accidental fat (masters, unused files).
3. Check pubspec for a dependency that snuck in transitive natives.
4. Confirm icon tree-shake line present.
5. Only then consider `--split-per-abi` APK sideloads for testers (AAB
   already splits on Play — don't over-engineer).
