# Sukoon (سکون)

Sukoon is an Android Flutter application for Pakistani Muslims focused on private, offline-first daily prayer support.

## Overview

Sukoon brings essential daily workflows into one app:
1. Prayer-time based auto-silent mode with safe restore behavior.
2. Offline prayer times for Pakistani cities.
3. Namaz tracking with streak and heatmap views.
4. Qaza-e-umri estimation and repayment planning tools.
5. Qibla direction support.

## Key Features

1. Auto-Silent at Prayer Time
- Activates alarms-only DND level at prayer start.
- Restores the previous interruption state after 15, 20, or 30 minutes.
- Supports one-tap Masjid Mode.
- Continues working across reboot and timezone changes.

2. Offline Prayer Times
- Adhan-based prayer calculations.
- Karachi calculation method by default.
- Hanafi Asr setting by default.
- Pakistan-focused city dataset.

3. Namaz Tracker
- Daily prayer logging with jamaat and missed states.
- Streak tracking and heatmap visualization.
- Period mode support.

4. Qaza-e-Umri Planner
- Guided estimate flow with editable assumptions.
- Ledger and repayment planning tools.

5. Qibla Support
- Compass-based direction support.
- Mathematical bearing fallback.

6. Localization
- Full English and Urdu experience.
- RTL-aware Urdu interface.

## Technical Summary

Architecture follows clear separation of responsibilities:
- Flutter (Dart): UI, domain logic, local data, and feature modules.
- Android (Kotlin): exact alarms, DND handling, and background receivers.

Schedule synchronization is performed through MethodChannels, enabling exact-time native behavior even when the Flutter engine is not active.

## Scope and Policies

- Platform: Android.
- Data model: local-first; no backend required for core features.
- Monetization: no ads.
- Content policy: no Quran or Hadith text inside the app.

## Repository Layout

- lib: Flutter application source.
- android: native Android integration and receivers.
- assets: fonts, brand assets, and city data.
- docs: verification, release, and policy documentation.
- test: unit and logic tests.

## Development Notes

- Current implementation is under active verification and hardening.
- Detailed project status is maintained in docs/PROJECT_STATE.md.
- Verification waves are documented in docs/VERIFY_PLAN.md.
- Environment and setup guidance is documented in INSTALL.md.

## Screenshots

Sukoon provides a clean, intuitive interface for daily prayer management. Here's a quick visual tour of the key features:

<div align="center">

### Home & Dashboard
<p align="center">
  <img src="assets/screenshots/home_screen.jpeg" alt="Sukoon Home Screen" width="250"/>
  <br/>
  <em>Main dashboard showing today's prayer times and status</em>
</p>

### City Selection & Location
<p align="center">
  <img src="assets/screenshots/city_selection_screen.jpeg" alt="City Selection Screen" width="250"/>
  <br/>
  <em>Offline prayer times for Pakistani cities</em>
</p>

### Permission Management
<p align="center">
  <img src="assets/screenshots/permission_screen.jpeg" alt="Permission Screen" width="250"/>
  <br/>
  <em>Required permissions for prayer time notifications</em>
</p>

### Settings Configuration
<p align="center">
  <img src="assets/screenshots/settings_screen_1.jpeg" alt="Settings Screen 1" width="250"/>
  <img src="assets/screenshots/settings_screen_2.jpeg" alt="Settings Screen 2" width="250"/>
  <img src="assets/screenshots/settings_screen_3.jpeg" alt="Settings Screen 3" width="250"/>
  <br/>
  <em>Three settings screens covering general, prayer, and notification preferences</em>
</p>

### Prayer Tracker
<p align="center">
  <img src="assets/screenshots/tracker_screen.jpeg" alt="Prayer Tracker Screen" width="250"/>
  <br/>
  <em>Daily namaz tracking with streak and heatmap views</em>
</p>

### Qibla Direction Finder
<p align="center">
  <img src="assets/screenshots/qibla_finder.jpeg" alt="Qibla Direction Finder" width="250"/>
  <br/>
  <em>Compass-based Qibla direction with mathematical bearing fallback</em>
</p>

</div>

*All screenshots are taken in release mode on an Android device. The app supports both English and Urdu languages.*


