import 'package:flutter/material.dart';

import 'package:sukoon/core/location.dart';
import 'package:sukoon/core/prefs.dart';
import 'package:sukoon/features/home/home_screen.dart';
import 'package:sukoon/features/qaza/qaza_screen.dart';
import 'package:sukoon/features/qibla/qibla_screen.dart';
import 'package:sukoon/features/settings/primers.dart';
import 'package:sukoon/features/settings/settings_screen.dart';
import 'package:sukoon/features/tracker/tracker_screen.dart';
import 'package:sukoon/l10n/gen/app_localizations.dart';
import 'package:sukoon/native/dnd_channel.dart';
import 'package:sukoon/native/schedule_sync.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int _index = 0;
  bool _bootstrapped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (_bootstrapped) return;
    _bootstrapped = true;

    // 1. First-run primer (explains DND before Android asks for it).
    if (!Prefs.primerShown && mounted) {
      await Navigator.of(context).push(MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => const FirstRunPrimer(),
      ));
      await Prefs.setPrimerShown();
    }

    // 2. Best-effort coarse location (falls back to saved city). Silent: we
    //    never stack the OS location dialog on top of the first-run primer —
    //    GPS is opt-in from Settings.
    await LocationService.refresh(silent: true);

    // 3. Push the 7-day schedule to the native side.
    if (!mounted) return;
    await ScheduleSync.push(AppLocalizations.of(context));

    // 4. One-time battery-exemption sheet, only when core is granted.
    if (!Prefs.batterySheetShown) {
      final st = await DndChannel.getStatus();
      if (st.policyGranted &&
          st.exactAllowed &&
          !st.batteryExempt &&
          mounted) {
        await showBatterySheet(context);
        await Prefs.setBatterySheetShown();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      // Settings may have changed outside the app (permission toggles),
      // and the schedule shrinks as time passes — refresh both.
      setState(() {});
      ScheduleSync.push(AppLocalizations.of(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          TrackerScreen(),
          QazaScreen(),
          QiblaScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.tabHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.check_circle_outline),
            selectedIcon: const Icon(Icons.check_circle),
            label: l10n.tabTracker,
          ),
          NavigationDestination(
            icon: const Icon(Icons.restore_outlined),
            selectedIcon: const Icon(Icons.restore),
            label: l10n.tabQaza,
          ),
          NavigationDestination(
            icon: const Icon(Icons.explore_outlined),
            selectedIcon: const Icon(Icons.explore),
            label: l10n.tabQibla,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.tabSettings,
          ),
        ],
      ),
    );
  }
}
