import 'package:flutter/material.dart';

import 'package:sukoon/core/l10n_ext.dart';
import 'package:sukoon/features/common/widgets.dart';
import 'package:sukoon/l10n/gen/app_localizations.dart';
import 'package:sukoon/qaza/qaza_estimator.dart';
import 'package:sukoon/theme.dart';

/// "How was this calculated?" — renders every step of the estimate so the
/// number is never a black box (trust matters more than cleverness here).
class ExplainerScreen extends StatelessWidget {
  const ExplainerScreen({super.key, required this.estimate});

  final QazaEstimate estimate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final e = estimate;

    Widget row(String label, String value, {bool strong = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(label,
                    style: t.bodyMedium
                        ?.copyWith(color: SukoonColors.textSecondary)),
              ),
              const SizedBox(width: 12),
              Text(value,
                  style: strong
                      ? t.titleMedium?.copyWith(color: SukoonColors.accent)
                      : t.bodyLarge),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.expTitle)),
      body: SafeArea(
        child: ListView(
          padding: kScreenPad,
          children: [
            SectionCard(
              child: Column(
                children: [
                  row(l10n.expBulugh,
                      formatShortDate(l10n.localeName, e.bulughDate)),
                  row(l10n.expGapEnd,
                      formatShortDate(l10n.localeName, e.gapEnd)),
                  const Divider(color: SukoonColors.stroke),
                  row(l10n.expGapDays, '${e.gapDays}'),
                  if (e.haydDeduction > 0)
                    row(l10n.expHayd, '−${e.haydDeduction.round()}'),
                  if (e.nifasDeduction > 0)
                    row(l10n.expNifas, '−${e.nifasDeduction.round()}'),
                  row(l10n.expObligated, '${e.obligatedDays.round()}'),
                  if (e.prayedFraction > 0)
                    row(
                        l10n.expAdherence(
                            (e.prayedFraction * 100).round()),
                        '× ${(1 - e.prayedFraction).toStringAsFixed(2)}'),
                  const Divider(color: SukoonColors.stroke),
                  row(l10n.expOwedDays, '${e.owedDays}', strong: true),
                  row(l10n.expPerPrayer(e.perPrayer.length),
                      '${e.totalOwed}',
                      strong: true),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              borderColor: SukoonColors.stroke,
              child: Text(l10n.expNote,
                  style: t.bodySmall
                      ?.copyWith(color: SukoonColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}
