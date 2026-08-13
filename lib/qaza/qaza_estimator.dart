/// Qaza-e-umri estimation engine.
///
/// PURE DART — no Flutter imports — hand-verified tests in
/// test/qaza_estimator_test.dart. Every constant is documented because the
/// explainer screen renders this logic step by step.
///
/// FIQH MODEL (Sunni, Hanafi-leaning defaults; docs/COPY_REVIEW.md):
/// - Prayers become obligatory at bulugh (maturity), not a fixed birthday.
/// - If the user remembers when they matured, use that.
/// - If not: DEEMED bulugh at 15 lunar years (≈ 14y 7m solar) — the fatwa
///   position when no signs are remembered.
/// - CAUTIOUS mode: earliest possible bulugh — 12 lunar years (boys) /
///   9 lunar years (girls).
/// - Women deduct average hayd days (user-set 3–10/month, default 7) and
///   nifas (up to 40 days per birth) — no prayers are owed for those days.
/// - Hanafi default includes Witr as a 6th owed prayer (toggleable).
/// - Output is ALWAYS an estimate; the UI must show the edit-and-confirm
///   flow and the "confirm with your local scholar" disclaimer.
library;

import 'dart:math' as math;

import 'package:sukoon/constants.dart';

/// Average length of a lunar (hijri) year in days.
const double lunarYearDays = 354.367;

/// Deemed bulugh when no signs are remembered (lunar years).
const int deemedBulughLunarYears = 15;

/// Earliest possible bulugh (lunar years).
const int cautiousMaleLunarYears = 12;
const int cautiousFemaleLunarYears = 9;

/// Average Gregorian month length — used to spread hayd days over the gap.
const double avgMonthDays = 30.44;

enum Gender { male, female }

enum BulughMode {
  /// User remembers (approximately) when they matured.
  remembered,

  /// Deemed 15 lunar years — default when nothing is remembered.
  deemed,

  /// Earliest possible (12 lunar boys / 9 lunar girls) — strictest estimate.
  cautious,
}

class QazaInputs {
  const QazaInputs({
    required this.gender,
    required this.birthDate,
    required this.bulughMode,
    this.rememberedBulughDate,
    this.regularSince,
    this.prayedFraction = 0.0,
    this.haydDaysPerMonth = 7,
    this.births = 0,
    this.nifasDaysPerBirth = 40,
    this.includeWitr = true,
  })  : assert(prayedFraction >= 0 && prayedFraction <= 0.9),
        assert(haydDaysPerMonth >= 3 && haydDaysPerMonth <= 10),
        assert(births >= 0),
        assert(nifasDaysPerBirth >= 0 && nifasDaysPerBirth <= 40);

  final Gender gender;
  final DateTime birthDate;
  final BulughMode bulughMode;

  /// Required when [bulughMode] == remembered.
  final DateTime? rememberedBulughDate;

  /// Since when the user has prayed all five regularly; null = not yet
  /// (the gap runs to today).
  final DateTime? regularSince;

  /// Fraction of prayers performed DURING the gap years (0.0–0.9).
  final double prayedFraction;

  final int haydDaysPerMonth;
  final int births;
  final int nifasDaysPerBirth;
  final bool includeWitr;
}

class QazaEstimate {
  const QazaEstimate({
    required this.bulughDate,
    required this.gapEnd,
    required this.gapDays,
    required this.haydDeduction,
    required this.nifasDeduction,
    required this.obligatedDays,
    required this.prayedFraction,
    required this.owedDays,
    required this.perPrayer,
  });

  final DateTime bulughDate;
  final DateTime gapEnd;

  /// Whole days between bulugh and gap end (never negative).
  final int gapDays;

  /// Estimated hayd days across the gap (female; 0 for male).
  final double haydDeduction;

  /// births × nifas days (female; 0 for male).
  final double nifasDeduction;

  /// gapDays − hayd − nifas, floored at 0. Days on which prayers were owed.
  final double obligatedDays;

  final double prayedFraction;

  /// ceil(obligatedDays × (1 − prayedFraction)) — owed days, i.e. the owed
  /// count for EACH prayer type.
  final int owedDays;

  /// prayer key → owed count (5 rows, or 6 with witr).
  final Map<String, int> perPrayer;

  int get totalOwed =>
      perPrayer.values.fold(0, (sum, v) => sum + v);
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Bulugh date for the given inputs (also used by the wizard preview).
DateTime bulughDateFor(QazaInputs i) {
  switch (i.bulughMode) {
    case BulughMode.remembered:
      return _dateOnly(i.rememberedBulughDate!);
    case BulughMode.deemed:
      return _dateOnly(i.birthDate)
          .add(Duration(days: (deemedBulughLunarYears * lunarYearDays).round()));
    case BulughMode.cautious:
      final years = i.gender == Gender.male
          ? cautiousMaleLunarYears
          : cautiousFemaleLunarYears;
      return _dateOnly(i.birthDate)
          .add(Duration(days: (years * lunarYearDays).round()));
  }
}

QazaEstimate estimateQaza(QazaInputs i, {DateTime? asOf}) {
  final bulugh = bulughDateFor(i);
  final gapEnd = _dateOnly(i.regularSince ?? asOf ?? DateTime.now());

  var gapDays = gapEnd.difference(bulugh).inDays;
  if (gapDays < 0) gapDays = 0;

  var hayd = 0.0;
  var nifas = 0.0;
  if (i.gender == Gender.female) {
    hayd = gapDays / avgMonthDays * i.haydDaysPerMonth;
    nifas = (i.births * math.min(i.nifasDaysPerBirth, 40)).toDouble();
  }

  var obligated = gapDays - hayd - nifas;
  if (obligated < 0) obligated = 0;

  final owedDays = (obligated * (1 - i.prayedFraction)).ceil();

  final prayers = i.includeWitr ? PrayerKeys.six : PrayerKeys.five;
  return QazaEstimate(
    bulughDate: bulugh,
    gapEnd: gapEnd,
    gapDays: gapDays,
    haydDeduction: hayd,
    nifasDeduction: nifas,
    obligatedDays: obligated,
    prayedFraction: i.prayedFraction,
    owedDays: owedDays,
    perPrayer: {for (final p in prayers) p: owedDays},
  );
}
