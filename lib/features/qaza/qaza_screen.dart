import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sukoon/constants.dart';
import 'package:sukoon/core/l10n_ext.dart';
import 'package:sukoon/core/prefs.dart';
import 'package:sukoon/data/qaza_repository.dart';
import 'package:sukoon/features/qaza/dashboard.dart';
import 'package:sukoon/features/qaza/wizard.dart';
import 'package:sukoon/l10n/gen/app_localizations.dart';
import 'package:sukoon/theme.dart';

/// Routes between the intro (wizard not yet run) and the dashboard.
class QazaScreen extends StatelessWidget {
  const QazaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: Prefs.revision,
      builder: (context, _, __) {
        if (Prefs.qazaWizardDone) return const QazaDashboard();
        return const _QazaIntro();
      },
    );
  }
}

class _QazaIntro extends StatelessWidget {
  const _QazaIntro();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: kScreenPad,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.tabQaza, style: t.titleLarge),
            const Spacer(),
            Center(
              child: Image.asset(
                'assets/illustrations/moon.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.qazaEmptyTitle,
                style: t.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(l10n.qazaEmptyBody,
                style:
                    t.bodyMedium?.copyWith(color: SukoonColors.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                    fullscreenDialog: true,
                    builder: (_) => const QazaWizard()),
              ),
              child: Text(l10n.qazaStart),
            ),
            const SizedBox(height: 10),
            // Simple path — skip the wizard entirely and type the numbers.
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                    fullscreenDialog: true,
                    builder: (_) => const ManualQazaEntryScreen()),
              ),
              child: Text(l10n.qazaManualStart),
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}

/// Dead-simple manual entry — six number fields, one Save button.
/// For people who already know (or roughly know) their owed counts.
class ManualQazaEntryScreen extends StatefulWidget {
  const ManualQazaEntryScreen({super.key});

  @override
  State<ManualQazaEntryScreen> createState() => _ManualQazaEntryScreenState();
}

class _ManualQazaEntryScreenState extends State<ManualQazaEntryScreen> {
  late final Map<String, TextEditingController> _controllers = {
    for (final p in PrayerKeys.six) p: TextEditingController(text: '0'),
  };

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  int get _total => _controllers.values
      .fold(0, (sum, c) => sum + (int.tryParse(c.text) ?? 0));

  Future<void> _save() async {
    final counts = {
      for (final e in _controllers.entries)
        e.key: (int.tryParse(e.value.text) ?? 0).clamp(0, 1000000),
    };
    await QazaRepository.initLedger(counts);
    await QazaRepository.consumePendingMissed();
    await Prefs.setQazaWizardDone(true);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.qazaManualTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: kScreenPad,
                children: [
                  Text(l10n.qazaManualHint,
                      style: t.bodyMedium
                          ?.copyWith(color: SukoonColors.textSecondary)),
                  const SizedBox(height: 16),
                  for (final prayer in PrayerKeys.six)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(prayerName(l10n, prayer),
                                style: t.titleMedium),
                          ),
                          SizedBox(
                            width: 120,
                            child: TextField(
                              controller: _controllers[prayer],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(7),
                              ],
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: SukoonColors.card,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: SukoonColors.stroke),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      '${l10n.wizTotalLabel}: $_total',
                      style: t.titleMedium
                          ?.copyWith(color: SukoonColors.accent),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  child: Text(l10n.save),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
