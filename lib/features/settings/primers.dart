import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:sukoon/features/common/widgets.dart';
import 'package:sukoon/l10n/gen/app_localizations.dart';
import 'package:sukoon/native/alarms_channel.dart';
import 'package:sukoon/native/dnd_channel.dart';
import 'package:sukoon/theme.dart';

/// True when running somewhere the native Android channels can't exist
/// (web / desktop preview). Permission actions then explain instead of
/// silently doing nothing.
bool get _channelsUnavailable =>
    kIsWeb ||
    defaultTargetPlatform != TargetPlatform.android;

void _showAndroidOnlyNotice(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(l10n.androidOnlyNotice)));
}

/// First-run explainer. Shown BEFORE Android's scary DND-access screen so
/// the user understands why (Play policy also expects this).
class FirstRunPrimer extends StatefulWidget {
  const FirstRunPrimer({super.key});

  @override
  State<FirstRunPrimer> createState() => _FirstRunPrimerState();
}

class _FirstRunPrimerState extends State<FirstRunPrimer>
    with WidgetsBindingObserver {
  DndStatus _status = DndStatus.unknown;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back from a system settings page — re-check what was granted.
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final st = await DndChannel.getStatus();
    if (mounted) setState(() => _status = st);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: kScreenPad,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              // Brand mark — no emoji.
              Center(
                child: Image.asset(
                  'assets/illustrations/logo.png',
                  width: 84,
                  height: 84,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
              Text(l10n.primerTitle,
                  style: t.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(l10n.primerBody,
                  style: t.bodyMedium
                      ?.copyWith(color: SukoonColors.textSecondary),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    _PermCard(
                      granted: _status.policyGranted,
                      icon: Icons.notifications_off_outlined,
                      title: l10n.primerDndTitle,
                      body: l10n.primerDndBody,
                      buttonLabel: l10n.primerAllow,
                      onPressed: () async {
                        if (_channelsUnavailable) {
                          _showAndroidOnlyNotice(context);
                          return;
                        }
                        await DndChannel.openPolicyAccessSettings();
                      },
                    ),
                    const SizedBox(height: 10),
                    _PermCard(
                      granted: _status.exactAllowed,
                      icon: Icons.alarm_on_outlined,
                      title: l10n.primerExactTitle,
                      body: l10n.primerExactBody,
                      buttonLabel: l10n.primerAllow,
                      onPressed: () async {
                        if (_channelsUnavailable) {
                          _showAndroidOnlyNotice(context);
                          return;
                        }
                        await AlarmsChannel.requestExactAlarmAccess();
                        await _refresh();
                      },
                    ),
                    const SizedBox(height: 10),
                    _PermCard(
                      granted: _status.notifGranted,
                      icon: Icons.notifications_active_outlined,
                      title: l10n.primerNotifTitle,
                      body: l10n.primerNotifBody,
                      buttonLabel: l10n.primerAllow,
                      onPressed: () async {
                        if (_channelsUnavailable) {
                          _showAndroidOnlyNotice(context);
                          return;
                        }
                        await DndChannel.requestPostNotifications();
                        await _refresh();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(_status.coreGranted
                    ? l10n.primerDone
                    : l10n.primerSkip),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermCard extends StatelessWidget {
  const _PermCard({
    required this.granted,
    required this.icon,
    required this.title,
    required this.body,
    required this.buttonLabel,
    required this.onPressed,
  });

  final bool granted;
  final IconData icon;
  final String title;
  final String body;
  final String buttonLabel;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              color: granted ? SukoonColors.lime : SukoonColors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(title, style: t.titleMedium)),
                    StatusDot(granted),
                  ],
                ),
                const SizedBox(height: 4),
                Text(body,
                    style: t.bodySmall
                        ?.copyWith(color: SukoonColors.textSecondary)),
                if (!granted) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: OutlinedButton(
                      onPressed: () => onPressed(),
                      child: Text(buttonLabel),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One-time sheet asking to exempt Sukoon from battery optimization
/// (Tecno/Infinix/Xiaomi kill background alarms aggressively).
Future<void> showBatterySheet(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isDismissible: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.batterySheetTitle,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(l10n.batterySheetBody,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: SukoonColors.textSecondary)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                if (_channelsUnavailable) return;
                await DndChannel.requestIgnoreBatteryOptimizations();
              },
              child: Text(l10n.batterySheetButton),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.batterySheetLater),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Permission center — all four switches with fix actions. Reused by the
/// Home banner and Settings.
Future<void> showPermissionSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => const SafeArea(child: _PermissionSheetBody()),
  );
}

class _PermissionSheetBody extends StatefulWidget {
  const _PermissionSheetBody();

  @override
  State<_PermissionSheetBody> createState() => _PermissionSheetBodyState();
}

class _PermissionSheetBodyState extends State<_PermissionSheetBody>
    with WidgetsBindingObserver {
  DndStatus _status = DndStatus.unknown;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final st = await DndChannel.getStatus();
    if (mounted) setState(() => _status = st);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.permSheetTitle,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _row(l10n.permDnd, _status.policyGranted, () async {
            await DndChannel.openPolicyAccessSettings();
          }),
          _row(l10n.permExact, _status.exactAllowed, () async {
            await AlarmsChannel.requestExactAlarmAccess();
            await _refresh();
          }),
          _row(l10n.permNotif, _status.notifGranted, () async {
            await DndChannel.requestPostNotifications();
            await _refresh();
          }),
          _row(l10n.permBattery, _status.batteryExempt, () async {
            await DndChannel.requestIgnoreBatteryOptimizations();
            await _refresh();
          }),
        ],
      ),
    );
  }

  Widget _row(String label, bool ok, Future<void> Function() fix) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          StatusDot(ok),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
          if (!ok)
            TextButton(
              onPressed: () {
                if (_channelsUnavailable) {
                  _showAndroidOnlyNotice(context);
                  return;
                }
                fix();
              },
              child: Text(l10n.permFix),
            )
          else
            const Icon(Icons.check, size: 18, color: SukoonColors.lime),
        ],
      ),
    );
  }
}
