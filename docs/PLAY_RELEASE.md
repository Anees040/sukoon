# PLAY_RELEASE — signing, console setup, and the 14-day clock

## 0. The schedule trick (why tonight matters)

New personal Play Console accounts must run a **closed test with ≥12
testers for 14 continuous days** before production access. The clock starts
when the closed test is live with testers — NOT when the app is finished.

- **Tonight (Aug 11–12):** create the account, invite testers.
- **Aug 21–22:** upload the first working aab → closed test live → Gate 1 (Aug 23).
- **Sep 4–5:** 14 days elapsed → apply for production → Gate 2 (Sep 6).

## 1. Play Console account (manual, ~30 min)

1. <https://play.google.com/console> → sign up — personal account — $25 one-time.
2. Identity verification can take 1–2 days — do it FIRST.
3. Create app: **Sukoon: Auto Silent for Namaz** · App · Free · Lifestyle.
4. Gather 12+ testers now (class WhatsApp group is perfect): collect the
   Gmail addresses, make a Google Group, add it under Testing → Closed
   testing → Testers.

## 2. Keystore (manual, 5 min — do once, back it up twice)

```powershell
keytool -genkey -v -keystore $env:USERPROFILE\sukoon.jks -keyalg RSA -keysize 2048 -validity 10000 -alias sukoon
```

Then create `android/key.properties` (git-ignored — NEVER commit):

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=sukoon
storeFile=C:\\Users\\YOURUSER\\sukoon.jks
```

`android/app/build.gradle.kts` already reads this file and falls back to
debug signing when it's absent. **Back up sukoon.jks + passwords to Google
Drive AND a USB stick — losing it means losing the app identity forever.**

## 3. Build & upload (V-6 wave does this with you)

```powershell
flutter build appbundle --release --analyze-size
```

Upload `build/app/outputs/bundle/release/app-release.aab` to Closed testing
→ create release → add release notes (one line is fine) → roll out.

## 4. App content forms (Console → App content) — answers

| Form | Answer |
|---|---|
| Privacy policy | URL of hosted docs/privacy-policy.md |
| Ads | No ads |
| App access | All functionality available without special access |
| Content rating | Utility/Lifestyle → questionnaire → Everyone |
| Target audience | 13+ (do NOT tick under-13) |
| News app | No |
| COVID-19 | No |
| Data safety | **No data collected, no data shared.** Location: collected? NO (processed on-device only, never leaves it). If the form forces a location entry because of the permission: “collected, not shared, processed ephemerally, required for app functionality” — but prefer the truthful “not collected” since nothing is transmitted. |
| Government app | No |
| Financial features | None |

## 5. Sensitive permissions declaration

Play flags `SCHEDULE_EXACT_ALARM`. Declaration text (also reusable if
reviewers ask about DND access):

> Sukoon is a prayer-time utility. It uses exact alarms to silence the
> device precisely at Islamic prayer times chosen by the user and to restore
> the ringer when the chosen window ends. Alarms are user-scheduled,
> recurring daily religious events; inexact timing would defeat the app's
> core purpose. Do-Not-Disturb access is used solely to toggle the
> interruption filter during these windows and restore the user's previous
> setting afterwards.

(DND access itself is granted by the user in system settings — no Play
declaration needed — but keep this text handy for review appeals.)

## 6. Release checklist (V-6 runs through this)

- [ ] `flutter test` green · `flutter analyze` clean
- [ ] versionName/versionCode bumped (0.9.0+1 → 0.9.1+2 → … → 1.0.0+3 for production)
- [ ] aab ≤ 25 MB (target 12–18) — record size in PROJECT_STATE.md
- [ ] Release build smoke test on device (V-2 steps 4–5 minimum)
- [ ] Screenshots ×6–8 uploaded (EN + UR mix per listing_en.md)
- [ ] Privacy policy URL live
- [ ] 12+ testers opted in (send them the opt-in link!)
- [ ] Day-14 date noted → calendar reminder to apply for production

## 7. After Gate 1 (while the clock runs)

Keep shipping to the closed track every few days — each upload is just a
versionCode bump. Testers get updates automatically. Collect reviews with
docs/REVIEW_TEMPLATE.md.
