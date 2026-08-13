# Sukoon (سکون)

Sukoon is an Android-first Flutter application for Pakistani Muslims that provides offline prayer support tools with strong privacy defaults and bilingual experience in English and Urdu.

It combines practical daily workflows in one place:
- Prayer-time based auto-silence with safe restore behavior
- Offline prayer times for Pakistani cities
- Daily namaz tracking with streak and heatmap views
- Qaza-e-umri estimation and planning tools
- Qibla direction support

## Product Scope

Current scope is intentionally focused and lightweight:
- Platform: Android
- Network: No backend, no account system, no analytics dependency
- Monetization: No ads
- Religious content policy: No Quran or Hadith text in-app

## Core Features

1. Auto-Silent at Prayer Time
- Enables alarms-only DND level at prayer start
- Restores the user's previous interruption state after configured duration (15/20/30 min)
- Includes one-tap Masjid Mode
- Works through reboot and timezone changes using native alarm receivers

2. Offline Prayer Times
- Adhan-based prayer calculations
- Karachi method default, Hanafi Asr default
- City dataset focused on Pakistan

3. Namaz Tracker
- Daily prayer logging (including jamaat and missed)
- Streak tracking
- Monthly heatmap view
- Period mode support

4. Qaza-e-Umri Planner
- Guided estimate flow with editable assumptions
- Ledger and repayment planning view
- Achievement progression for consistency motivation

5. Qibla Utilities
- Compass-based direction support
- Mathematical bearing fallback

6. Full Localization
- English and Urdu user experience
- RTL-aware Urdu interface support

## Technical Architecture

Sukoon follows a split-responsibility architecture:
- Flutter (Dart) layer handles UI, prayer math integration, local app state, and domain features
- Native Android (Kotlin) layer handles exact alarms, DND switching, and background-safe receivers

High-level flow:
1. Dart calculates upcoming schedule payload.
2. Payload is synced to native storage through MethodChannel bridge.
3. Native receivers execute exact-time behaviors even when the Flutter engine is not active.
4. Original interruption filter is restored safely after session end.

## Repository Structure

- lib: Flutter application source code (features, domain modules, UI, localization)
- android: Native Android implementation (channels, alarms, receivers)
- assets: City data, fonts, and visual assets
- docs: Verification plans, release notes, content policy, and supporting documentation
- test: Unit tests for planner logic, qibla math, schedule payloads, and localization parity

## Local Setup

Prerequisites:
- Flutter SDK 3.35.x (or project-compatible stable version)
- Android SDK and Android platform tools
- A physical Android device (recommended for DND and exact-alarm behavior validation)

Basic setup:
1. Clone repository.
2. Run dependency install.
3. Generate localization files.
4. Run static analysis and tests.

Commands:
- flutter pub get
- flutter gen-l10n
- flutter analyze
- flutter test

## Build and Release

Debug run on connected device:
- flutter run -d <device-id>

Release APK build:
- flutter build apk --release

Play Store AAB build:
- flutter build appbundle --release

Size analysis:
- flutter build appbundle --release --analyze-size

## Privacy and Permissions

The app is designed with local-first behavior and minimal data exposure:
- No remote backend required for core operation
- Local persistence for settings and user activity logs
- Runtime behavior depends on explicit user-granted Android capabilities (for example DND access and exact alarms)

## Screenshots

Screenshots will be added after device-side release validation.

## Current Development Status

The codebase is under active verification and hardening. For detailed wave-by-wave technical status and acceptance criteria, refer to:
- docs/PROJECT_STATE.md
- docs/VERIFY_PLAN.md
- INSTALL.md

## Contribution and Quality Notes

- Keep changes scoped and test-backed
- Prefer minimal-risk fixes over broad refactors
- Preserve localization parity across English and Urdu
- Maintain strict Android runtime safety checks for permissions and scheduling
