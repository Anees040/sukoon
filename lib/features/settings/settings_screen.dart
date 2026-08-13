import 'package:flutter/material.dart';

import 'package:sukoon/constants.dart';
import 'package:sukoon/core/l10n_ext.dart';
import 'package:sukoon/core/locale_controller.dart';
import 'package:sukoon/core/location.dart';
import 'package:sukoon/core/prefs.dart';
import 'package:sukoon/features/cities/cities_screen.dart';
import 'package:sukoon/features/common/widgets.dart';
import 'package:sukoon/features/settings/primers.dart';
import 'package:sukoon/l10n/gen/app_localizations.dart';
import 'package:sukoon/native/schedule_sync.dart';
import 'package:sukoon/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _sync() async {
    if (!mounted) return;
    await ScheduleSync.push(AppLocalizations.of(context));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;

    Widget header(String s) => Padding(
          padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
          child: Text(s,
              style: t.labelLarge?.copyWith(color: SukoonColors.accent)),
        );

    return SafeArea(
      child: ListView(
        padding: kScreenPad,
        children: [
          Text(l10n.tabSettings, style: t.titleLarge),

          // ---- auto-silent ----
          header(l10n.sectionSilent),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.settingsSilenceDuration, style: t.titleSmall),
                const SizedBox(height: 10),
                SegmentedButton<int>(
                  segments: [
                    for (final m in const [15, 20, 30])
                      ButtonSegment(value: m, label: Text('$m')),
                  ],
                  selected: {Prefs.silenceMinutes},
                  onSelectionChanged: (s) async {
                    await Prefs.setSilenceMinutes(s.first);
                    await _sync();
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child:
                            Text(l10n.settingsSilenceNotif, style: t.bodyLarge)),
                    Switch(
                      value: Prefs.notifEnabled,
                      onChanged: (v) async {
                        await Prefs.setNotifEnabled(v);
                        await _sync();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ---- prayer times ----
          header(l10n.sectionPrayerTimes),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.settingsCalcMethod, style: t.titleSmall),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: Prefs.method,
                  items: [
                    DropdownMenuItem(
                        value: 'karachi', child: Text(l10n.methodKarachi)),
                    DropdownMenuItem(
                        value: 'mwl', child: Text(l10n.methodMwl)),
                    DropdownMenuItem(
                        value: 'isna', child: Text(l10n.methodIsna)),
                    DropdownMenuItem(
                        value: 'egyptian', child: Text(l10n.methodEgyptian)),
                  ],
                  onChanged: (v) async {
                    if (v == null) return;
                    await Prefs.setMethod(v);
                    await _sync();
                  },
                ),
                const SizedBox(height: 14),
                Text(l10n.settingsAsrMadhab, style: t.titleSmall),
                const SizedBox(height: 10),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                        value: 'hanafi', label: Text(l10n.madhabHanafi)),
                    ButtonSegment(
                        value: 'shafi', label: Text(l10n.madhabShafi)),
                  ],
                  selected: {Prefs.madhab},
                  onSelectionChanged: (s) async {
                    await Prefs.setMadhab(s.first);
                    await _sync();
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.place_outlined,
                        size: 18, color: SukoonColors.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                          '${l10n.settingsLocation}: ${Prefs.locationLabel}',
                          style: t.bodyLarge),
                    ),
                    TextButton(
                      onPressed: () async {
                        await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                                builder: (_) => const CitiesScreen()));
                        await _sync();
                      },
                      child: Text(l10n.settingsChangeCity),
                    ),
                  ],
                ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton.icon(
                    icon: const Icon(Icons.my_location, size: 16),
                    label: Text(l10n.settingsUseGps),
                    onPressed: () async {
                      // Captured before the gap — the snackbar target must not
                      // depend on the context surviving the GPS wait.
                      final messenger = ScaffoldMessenger.of(context);
                      final ok = await LocationService.refresh();
                      if (!ok) {
                        messenger.showSnackBar(SnackBar(
                            content: Text(l10n.settingsGpsFailed)));
                      }
                      await _sync();
                    },
                  ),
                ),
              ],
            ),
          ),

          // ---- language ----
          header(l10n.settingsLanguage),
          SectionCard(
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'system', label: Text(l10n.langSystem)),
                const ButtonSegment(value: 'en', label: Text('English')),
                const ButtonSegment(value: 'ur', label: Text('اردو')),
              ],
              selected: {LocaleController.instance.mode},
              onSelectionChanged: (s) async {
                await LocaleController.instance.set(s.first);
                // Notification strings are pre-localized — re-push. _sync()
                // reads AppLocalizations AFTER the switch, so the native side
                // gets the new locale's strings.
                await _sync();
              },
            ),
          ),

          // ---- notifications & reminders ----
          header(l10n.sectionReminders),
          SectionCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text(l10n.settingsPreAzan, style: t.bodyLarge)),
                    DropdownButton<int>(
                      value: Prefs.preAzanMinutes,
                      underline: const SizedBox.shrink(),
                      items: [
                        DropdownMenuItem(
                            value: 0, child: Text(l10n.preAzanOff)),
                        for (final m in const [5, 10, 15])
                          DropdownMenuItem(
                              value: m, child: Text(l10n.minutesFull(m))),
                      ],
                      onChanged: (v) async {
                        if (v == null) return;
                        await Prefs.setPreAzanMinutes(v);
                        await _sync();
                      },
                    ),
                  ],
                ),
                const Divider(height: 20, color: SukoonColors.stroke),
                Row(
                  children: [
                    Expanded(
                        child: Text(l10n.settingsQazaReminder,
                            style: t.bodyLarge)),
                    Switch(
                      value: Prefs.reminderEnabled,
                      onChanged: (v) async {
                        await Prefs.setReminderEnabled(v);
                        await _sync();
                      },
                    ),
                  ],
                ),
                if (Prefs.reminderEnabled)
                  Row(
                    children: [
                      Expanded(
                          child: Text(l10n.settingsReminderTime,
                              style: t.bodyMedium?.copyWith(
                                  color: SukoonColors.textSecondary))),
                      TextButton(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(
                                hour: Prefs.reminderHour,
                                minute: Prefs.reminderMinute),
                          );
                          if (picked != null) {
                            await Prefs.setReminderTime(
                                picked.hour, picked.minute);
                            await _sync();
                          }
                        },
                        child: Text(formatTime(
                            l10n.localeName,
                            DateTime(2000, 1, 1, Prefs.reminderHour,
                                Prefs.reminderMinute))),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // ---- qaza ----
          header(l10n.tabQaza),
          SectionCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text(l10n.settingsWitr, style: t.bodyLarge)),
                    Switch(
                      value: Prefs.witrEnabled,
                      onChanged: (v) async {
                        await Prefs.setWitrEnabled(v);
                        if (mounted) setState(() {});
                      },
                    ),
                  ],
                ),
                Text(l10n.settingsWitrHint,
                    style: t.bodySmall
                        ?.copyWith(color: SukoonColors.textFaint)),
                const Divider(height: 20, color: SukoonColors.stroke),
                Row(
                  children: [
                    Expanded(
                        child: Text(l10n.settingsMinutesPerQaza,
                            style: t.bodyLarge)),
                    Text(l10n.minutesFull(Prefs.minutesPerQaza),
                        style: t.bodyLarge
                            ?.copyWith(color: SukoonColors.accent)),
                  ],
                ),
                Slider(
                  value: Prefs.minutesPerQaza.toDouble(),
                  min: 3,
                  max: 10,
                  divisions: 7,
                  onChanged: (v) async {
                    await Prefs.setMinutesPerQaza(v.round());
                    if (mounted) setState(() {});
                  },
                ),
              ],
            ),
          ),

          // ---- other ----
          header(l10n.sectionOther),
          SectionCard(
            onTap: () => showPermissionSheet(context),
            child: Row(
              children: [
                const Icon(Icons.verified_user_outlined,
                    color: SukoonColors.accent),
                const SizedBox(width: 12),
                Expanded(
                    child:
                        Text(l10n.settingsPermissions, style: t.bodyLarge)),
                const Icon(Icons.chevron_right, color: SukoonColors.textFaint),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${AppInfo.appName} — ${AppInfo.appNameUrdu}',
                    style: t.titleMedium),
                const SizedBox(height: 4),
                Text(l10n.aboutVersion(AppInfo.version),
                    style: t.bodySmall
                        ?.copyWith(color: SukoonColors.textSecondary)),
                const SizedBox(height: 8),
                Text(l10n.aboutDisclaimer,
                    style: t.bodySmall
                        ?.copyWith(color: SukoonColors.textFaint)),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
