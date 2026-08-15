import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:sukoon/constants.dart';
import 'package:sukoon/core/l10n_ext.dart';
import 'package:sukoon/core/prefs.dart';
import 'package:sukoon/features/cities/cities_screen.dart';
import 'package:sukoon/features/common/widgets.dart';
import 'package:sukoon/features/settings/primers.dart';
import 'package:sukoon/l10n/gen/app_localizations.dart';
import 'package:sukoon/native/alarms_channel.dart';
import 'package:sukoon/native/dnd_channel.dart';
import 'package:sukoon/native/schedule_sync.dart';
import 'package:sukoon/prayer/prayer_service.dart';
import 'package:sukoon/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver {
  Timer? _ticker;
  DndStatus _status = DndStatus.unknown;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _refreshStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    final st = await DndChannel.getStatus();
    if (mounted) setState(() => _status = st);
  }

  Future<void> _sync() async {
    if (!mounted) return;
    await ScheduleSync.push(AppLocalizations.of(context));
    await _refreshStatus();
  }

  Future<void> _openMasjidSheet() async {
    final l10n = AppLocalizations.of(context);
    final minutes = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.masjidSheetTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              for (final m in const [15, 20, 30]) ...[
                FilledButton(
                  onPressed: () => Navigator.pop(context, m),
                  child: Text(l10n.minutesFull(m)),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
    if (minutes == null || !mounted) return;
    final ok = await AlarmsChannel.startManualSilence(minutes);
    if (!mounted) return;
    if (ok) {
      await _refreshStatus();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).masjidNeedAccess)));
      await showPermissionSheet(context);
      await _refreshStatus();
    }
  }

  Future<void> _endNow() async {
    await DndChannel.restoreRinger();
    await AlarmsChannel.cancelManualSilence();
    await _refreshStatus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final now = DateTime.now();

    final today = PrayerService.forDay(
      day: now,
      lat: Prefs.lat,
      lng: Prefs.lng,
      method: Prefs.method,
      madhab: Prefs.madhab,
    );
    final next = PrayerService.next(
      now: now,
      lat: Prefs.lat,
      lng: Prefs.lng,
      method: Prefs.method,
      madhab: Prefs.madhab,
    );
    final silencedNow = _status.sessionActive && _status.sessionEndMillis > 0;

    return SafeArea(
      child: ListView(
        padding: kScreenPad,
        children: [
          // Header: app name + location chip
          Row(
            children: [
              Text(AppInfo.appName, style: t.titleLarge),
              const Spacer(),
              ActionChip(
                avatar: const Icon(Icons.place_outlined,
                    size: 16, color: SukoonColors.accent),
                label: Text(Prefs.locationLabel),
                onPressed: () async {
                  await Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => const CitiesScreen()));
                  await _sync();
                  if (mounted) setState(() {});
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Hero: next prayer + countdown + silence state
          SectionCard(
            color: SukoonColors.surface,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.homeNextPrayer,
                    style: t.labelLarge
                        ?.copyWith(color: SukoonColors.textSecondary)),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(prayerName(l10n, next.prayer),
                        style: t.displaySmall
                            ?.copyWith(color: SukoonColors.accent)),
                    const Spacer(),
                    Text(formatTime(l10n.localeName, next.time),
                        style: t.headlineMedium),
                  ],
                ),
                const SizedBox(height: 4),
                Text(formatCountdown(next.time.difference(now)),
                    style: t.titleMedium
                        ?.copyWith(color: SukoonColors.textSecondary)),
                const SizedBox(height: 12),
                if (silencedNow)
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: SukoonColors.accentDim,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.notifications_off_outlined,
                                  size: 16),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  l10n.homeSilencedUntil(formatTime(
                                      l10n.localeName,
                                      DateTime.fromMillisecondsSinceEpoch(
                                          _status.sessionEndMillis))),
                                  style: t.labelLarge,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                          onPressed: _endNow, child: Text(l10n.endNow)),
                    ],
                  )
                else if (Prefs.masterEnabled &&
                    Prefs.prayerEnabled(next.prayer))
                  Text(
                    l10n.homeAutoSilenceAt(
                        formatTime(l10n.localeName,
                            next.time.add(Duration(
                                minutes: Prefs.jamatOffset(next.prayer)))),
                        Prefs.silenceMinutes),
                    style:
                        t.bodyMedium?.copyWith(color: SukoonColors.lime),
                  ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(
              begin: 0.04, curve: Curves.easeOutCubic, duration: 400.ms),
          const SizedBox(height: 12),

          // Permission banner
          if (!_status.coreGranted) ...[
            SectionCard(
              borderColor: SukoonColors.warning,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.homePermissionTitle,
                      style: t.titleMedium
                          ?.copyWith(color: SukoonColors.warning)),
                  const SizedBox(height: 4),
                  Text(l10n.homePermissionBody,
                      style: t.bodyMedium
                          ?.copyWith(color: SukoonColors.textSecondary)),
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: FilledButton(
                      onPressed: () async {
                        await showPermissionSheet(context);
                        await _refreshStatus();
                      },
                      child: Text(l10n.homeFixNow),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Master switch
          SectionCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.masterTitle, style: t.titleMedium),
                      if (!Prefs.masterEnabled)
                        Text(l10n.masterOffHint,
                            style: t.bodySmall?.copyWith(
                                color: SukoonColors.textSecondary)),
                    ],
                  ),
                ),
                Switch(
                  value: Prefs.masterEnabled,
                  onChanged: (v) async {
                    await Prefs.setMasterEnabled(v);
                    if (v) {
                      await _sync();
                    } else {
                      await AlarmsChannel.cancelAll();
                      await _refreshStatus();
                    }
                    if (mounted) setState(() {});
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Today's five prayers
          SectionCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                for (final entry in today.toMap().entries)
                  Row(
                    children: [
                      SizedBox(
                        width: 76,
                        child: Text(
                          formatTime(l10n.localeName, entry.value),
                          style: t.bodyMedium?.copyWith(
                              color: SukoonColors.textSecondary),
                        ),
                      ),
                      Expanded(
                        child: Text(prayerName(l10n, entry.key),
                            style: t.titleMedium?.copyWith(
                              color: entry.key == next.prayer
                                  ? SukoonColors.accent
                                  : SukoonColors.text,
                            )),
                      ),
                      Switch(
                        value: Prefs.prayerEnabled(entry.key),
                        onChanged: Prefs.masterEnabled
                            ? (v) async {
                                await Prefs.setPrayerEnabled(entry.key, v);
                                await _sync();
                                if (mounted) setState(() {});
                              }
                            : null,
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Masjid Mode
          SectionCard(
            onTap: _openMasjidSheet,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: SukoonColors.accentDim,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.mosque_outlined,
                      color: SukoonColors.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.masjidMode, style: t.titleMedium),
                      Text(l10n.masjidModeHint,
                          style: t.bodySmall?.copyWith(
                              color: SukoonColors.textSecondary)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: SukoonColors.textFaint),
              ],
            ),
          ),

          // Debug helpers (never visible in release builds)
          if (kDebugMode) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () async {
                    await AlarmsChannel.startManualSilence(1);
                    await _refreshStatus();
                  },
                  child: const Text('DEBUG: silence 1 min'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _endNow,
                  child: const Text('DEBUG: restore'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
