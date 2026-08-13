import 'package:flutter/material.dart';

import 'package:sukoon/core/l10n_ext.dart';
import 'package:sukoon/core/prefs.dart';
import 'package:sukoon/data/qaza_repository.dart';
import 'package:sukoon/features/common/widgets.dart';
import 'package:sukoon/features/qaza/explainer.dart';
import 'package:sukoon/l10n/gen/app_localizations.dart';
import 'package:sukoon/qaza/qaza_estimator.dart';
import 'package:sukoon/theme.dart';

enum _Step { gender, birth, bulugh, bulughDate, regular, adherence, female, witr, result }

/// One-question-per-screen estimation wizard. Ends in an EDITABLE result
/// table — the user always confirms/adjusts before anything is saved.
class QazaWizard extends StatefulWidget {
  const QazaWizard({super.key});

  @override
  State<QazaWizard> createState() => _QazaWizardState();
}

class _QazaWizardState extends State<QazaWizard> {
  int _index = 0;

  // answers
  Gender _gender = Gender.male;
  DateTime _birth = DateTime(2005, 1, 1);
  BulughMode _mode = BulughMode.deemed;
  DateTime? _bulughDate;
  bool _regularNow = false;
  DateTime? _regularSince;
  double _adherence = 0.0;
  int _haydDays = 7;
  int _births = 0;
  int _nifasDays = 40;
  bool _includeWitr = true;

  // result editing
  QazaEstimate? _estimate;
  Map<String, int> _edited = {};

  List<_Step> get _steps => [
        _Step.gender,
        _Step.birth,
        _Step.bulugh,
        if (_mode == BulughMode.remembered) _Step.bulughDate,
        _Step.regular,
        _Step.adherence,
        if (_gender == Gender.female) _Step.female,
        _Step.witr,
        _Step.result,
      ];

  QazaInputs get _inputs => QazaInputs(
        gender: _gender,
        birthDate: _birth,
        bulughMode: _mode,
        rememberedBulughDate: _bulughDate,
        regularSince: _regularNow ? _regularSince : null,
        prayedFraction: _adherence,
        haydDaysPerMonth: _haydDays,
        births: _births,
        nifasDaysPerBirth: _nifasDays,
        includeWitr: _includeWitr,
      );

  bool get _canNext {
    final step = _steps[_index];
    if (step == _Step.bulughDate) return _bulughDate != null;
    if (step == _Step.regular) return !_regularNow || _regularSince != null;
    return true;
  }

  void _next() {
    if (_index >= _steps.length - 1) return;
    final nextStep = _steps[_index + 1];
    if (nextStep == _Step.result) {
      final est = estimateQaza(_inputs);
      _estimate = est;
      _edited = Map.of(est.perPrayer);
    }
    setState(() => _index++);
  }

  void _back() {
    if (_index == 0) {
      Navigator.of(context).pop();
    } else {
      setState(() => _index--);
    }
  }

  Future<void> _confirm() async {
    await QazaRepository.initLedger(_edited);
    await QazaRepository.consumePendingMissed();
    await Prefs.setQazaWizardDone(true);
    if (mounted) Navigator.of(context).pop();
  }

  Future<DateTime?> _pickDate(DateTime initial) => showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(1940),
        lastDate: DateTime.now(),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final steps = _steps;
    final step = steps[_index];
    final isResult = step == _Step.result;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.wizTitle),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back), onPressed: _back),
      ),
      body: SafeArea(
        child: Padding(
          padding: kScreenPad,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // progress dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < steps.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _index ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i <= _index
                            ? SukoonColors.accent
                            : SukoonColors.cardRaised,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOutCubic,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween(
                              begin: const Offset(0.08, 0),
                              end: Offset.zero)
                          .animate(anim),
                      child: child,
                    ),
                  ),
                  child: SingleChildScrollView(
                    key: ValueKey(step),
                    child: _buildStep(context, step),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (isResult)
                FilledButton(
                    onPressed: _confirm, child: Text(l10n.wizConfirm))
              else
                FilledButton(
                  onPressed: _canNext ? _next : null,
                  child: Text(l10n.next),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _question(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(text, style: Theme.of(context).textTheme.headlineSmall),
      );

  Widget _choiceCard({
    required bool selected,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SectionCard(
        onTap: onTap,
        borderColor: selected ? SukoonColors.accent : SukoonColors.stroke,
        color: selected ? SukoonColors.accentDim : SukoonColors.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: t.titleMedium),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle,
                  style: t.bodySmall
                      ?.copyWith(color: SukoonColors.textSecondary)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _dateButton(DateTime? value, DateTime initial,
      void Function(DateTime) onPicked) {
    final l10n = AppLocalizations.of(context);
    return OutlinedButton.icon(
      icon: const Icon(Icons.event),
      label: Text(value == null
          ? l10n.wizPickDate
          : formatShortDate(l10n.localeName, value)),
      onPressed: () async {
        final d = await _pickDate(value ?? initial);
        if (d != null) onPicked(d);
      },
    );
  }

  Widget _buildStep(BuildContext context, _Step step) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;

    switch (step) {
      case _Step.gender:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _question(l10n.wizGenderQ),
            _choiceCard(
              selected: _gender == Gender.male,
              title: l10n.genderMale,
              onTap: () => setState(() => _gender = Gender.male),
            ),
            _choiceCard(
              selected: _gender == Gender.female,
              title: l10n.genderFemale,
              onTap: () => setState(() => _gender = Gender.female),
            ),
          ],
        );

      case _Step.birth:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _question(l10n.wizBirthQ),
            _dateButton(_birth, DateTime(2005, 1, 1),
                (d) => setState(() => _birth = d)),
          ],
        );

      case _Step.bulugh:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _question(l10n.wizBulughQ),
            _choiceCard(
              selected: _mode == BulughMode.remembered,
              title: l10n.bulughRemembered,
              subtitle: l10n.bulughRememberedHint,
              onTap: () => setState(() => _mode = BulughMode.remembered),
            ),
            _choiceCard(
              selected: _mode == BulughMode.deemed,
              title: l10n.bulughDeemed,
              subtitle: l10n.bulughDeemedHint,
              onTap: () => setState(() => _mode = BulughMode.deemed),
            ),
            _choiceCard(
              selected: _mode == BulughMode.cautious,
              title: l10n.bulughCautious,
              subtitle: l10n.bulughCautiousHint,
              onTap: () => setState(() => _mode = BulughMode.cautious),
            ),
          ],
        );

      case _Step.bulughDate:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _question(l10n.wizBulughDateQ),
            _dateButton(
                _bulughDate,
                DateTime(_birth.year + 14, _birth.month, 1),
                (d) => setState(() => _bulughDate = d)),
          ],
        );

      case _Step.regular:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _question(l10n.wizRegularQ),
            _choiceCard(
              selected: !_regularNow,
              title: l10n.wizRegularNotYet,
              onTap: () => setState(() => _regularNow = false),
            ),
            _choiceCard(
              selected: _regularNow,
              title: l10n.wizRegularPick,
              onTap: () => setState(() => _regularNow = true),
            ),
            if (_regularNow)
              _dateButton(_regularSince, DateTime.now(),
                  (d) => setState(() => _regularSince = d)),
          ],
        );

      case _Step.adherence:
        final pct = (_adherence * 100).round();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _question(l10n.wizAdherenceQ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (label, v) in [
                  (l10n.adherencePreset0, 0.0),
                  (l10n.adherencePreset25, 0.25),
                  (l10n.adherencePreset50, 0.5),
                  (l10n.adherencePreset75, 0.75),
                ])
                  ChoiceChip(
                    label: Text(label),
                    selected: (_adherence - v).abs() < 0.01,
                    onSelected: (_) => setState(() => _adherence = v),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(l10n.wizAdherenceValue(pct),
                style: t.titleMedium?.copyWith(color: SukoonColors.accent)),
            Slider(
              value: _adherence,
              min: 0,
              max: 0.9,
              divisions: 18,
              onChanged: (v) => setState(() => _adherence = v),
            ),
          ],
        );

      case _Step.female:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _question(l10n.wizFemaleQ),
            Text(l10n.wizFemaleHint,
                style: t.bodySmall
                    ?.copyWith(color: SukoonColors.textSecondary)),
            const SizedBox(height: 16),
            Text('${l10n.wizHaydLabel}: $_haydDays', style: t.bodyLarge),
            Slider(
              value: _haydDays.toDouble(),
              min: 3,
              max: 10,
              divisions: 7,
              onChanged: (v) => setState(() => _haydDays = v.round()),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: Text(l10n.wizBirthsLabel, style: t.bodyLarge)),
                IconButton(
                  onPressed: _births > 0
                      ? () => setState(() => _births--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('$_births', style: t.titleMedium),
                IconButton(
                  onPressed: () => setState(() => _births++),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            if (_births > 0) ...[
              Text('${l10n.wizNifasLabel}: $_nifasDays',
                  style: t.bodyLarge),
              Slider(
                value: _nifasDays.toDouble(),
                min: 0,
                max: 40,
                divisions: 40,
                onChanged: (v) => setState(() => _nifasDays = v.round()),
              ),
            ],
          ],
        );

      case _Step.witr:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _question(l10n.wizWitrQ),
            _choiceCard(
              selected: _includeWitr,
              title: '${l10n.prayerWitr} — ${l10n.wizWitrYes}',
              subtitle: l10n.wizWitrHint,
              onTap: () => setState(() => _includeWitr = true),
            ),
            _choiceCard(
              selected: !_includeWitr,
              title: l10n.wizWitrNo,
              onTap: () => setState(() => _includeWitr = false),
            ),
          ],
        );

      case _Step.result:
        final est = _estimate!;
        final total = _edited.values.fold(0, (a, b) => a + b);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _question(l10n.wizResultTitle),
            SectionCard(
              color: SukoonColors.surface,
              child: Column(
                children: [
                  CountUpText(total,
                      style: Theme.of(context)
                          .textTheme
                          .displaySmall
                          ?.copyWith(color: SukoonColors.accent)),
                  Text(l10n.wizTotalLabel,
                      style: t.bodySmall
                          ?.copyWith(color: SukoonColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(l10n.wizEditHint,
                style: t.bodySmall
                    ?.copyWith(color: SukoonColors.textSecondary)),
            const SizedBox(height: 8),
            for (final prayer in _edited.keys.toList())
              Row(
                children: [
                  Expanded(
                      child: Text(prayerName(l10n, prayer),
                          style: t.titleMedium)),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: _edited[prayer]! > 0
                        ? () => setState(() =>
                            _edited[prayer] = _edited[prayer]! - 1)
                        : null,
                  ),
                  SizedBox(
                    width: 64,
                    child: Text('${_edited[prayer]}',
                        textAlign: TextAlign.center,
                        style: t.titleMedium),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => setState(
                        () => _edited[prayer] = _edited[prayer]! + 1),
                  ),
                ],
              ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ExplainerScreen(estimate: est),
                ),
              ),
              child: Text(l10n.wizViewCalc),
            ),
            const SizedBox(height: 8),
            SectionCard(
              borderColor: SukoonColors.stroke,
              child: Text(l10n.wizDisclaimer,
                  style: t.bodySmall
                      ?.copyWith(color: SukoonColors.textSecondary)),
            ),
          ],
        );
    }
  }
}
