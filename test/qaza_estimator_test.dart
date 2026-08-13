import 'package:flutter_test/flutter_test.dart';
import 'package:sukoon/constants.dart';
import 'package:sukoon/qaza/qaza_estimator.dart';

/// Expected values were verified with an independent Python implementation
/// (tool/verify_math.py) — if these fail, the DART code changed, not the
/// expectations.
void main() {
  group('bulughDateFor', () {
    test('deemed bulugh (15 lunar years = 5316 days), birth 2000-03-15 → 2014-10-04',
        () {
      final i = QazaInputs(
        gender: Gender.male,
        birthDate: DateTime(2000, 3, 15),
        bulughMode: BulughMode.deemed,
      );
      expect(bulughDateFor(i), DateTime(2014, 10, 4));
    });

    test('cautious male = birth + 4252 days (12 lunar years)', () {
      final birth = DateTime(2000, 1, 1);
      final i = QazaInputs(
        gender: Gender.male,
        birthDate: birth,
        bulughMode: BulughMode.cautious,
      );
      expect(bulughDateFor(i), birth.add(const Duration(days: 4252)));
    });

    test('cautious female, birth 2000-03-15 → 2008-12-07 (3189 days)', () {
      final i = QazaInputs(
        gender: Gender.female,
        birthDate: DateTime(2000, 3, 15),
        bulughMode: BulughMode.cautious,
      );
      expect(bulughDateFor(i), DateTime(2008, 12, 7));
    });
  });

  group('estimateQaza', () {
    test('S1: male, 10-year gap, prayed nothing → 3652 owed each', () {
      final e = estimateQaza(QazaInputs(
        gender: Gender.male,
        birthDate: DateTime(1995, 6, 1),
        bulughMode: BulughMode.remembered,
        rememberedBulughDate: DateTime(2010, 1, 1),
        regularSince: DateTime(2020, 1, 1),
      ));
      expect(e.gapDays, 3652);
      expect(e.haydDeduction, 0.0);
      expect(e.nifasDeduction, 0.0);
      expect(e.owedDays, 3652);
      expect(e.perPrayer.length, 6); // witr on by default (Hanafi)
      expect(e.perPrayer[PrayerKeys.witr], 3652);
      expect(e.totalOwed, 21912);
    });

    test('S2: female, same gap, hayd 7/mo, 2 births → 2733 owed each', () {
      final e = estimateQaza(QazaInputs(
        gender: Gender.female,
        birthDate: DateTime(1995, 6, 1),
        bulughMode: BulughMode.remembered,
        rememberedBulughDate: DateTime(2010, 1, 1),
        regularSince: DateTime(2020, 1, 1),
        births: 2,
      ));
      expect(e.gapDays, 3652);
      expect(e.haydDeduction, closeTo(839.816, 0.01));
      expect(e.nifasDeduction, 80.0);
      expect(e.obligatedDays, closeTo(2732.184, 0.01));
      expect(e.owedDays, 2733); // ceil — always rounds AGAINST the user
      expect(e.totalOwed, 16398);
    });

    test('S3: 75% prayed during the gap → 913 owed each', () {
      final e = estimateQaza(QazaInputs(
        gender: Gender.male,
        birthDate: DateTime(1995, 6, 1),
        bulughMode: BulughMode.remembered,
        rememberedBulughDate: DateTime(2010, 1, 1),
        regularSince: DateTime(2020, 1, 1),
        prayedFraction: 0.75,
      ));
      expect(e.owedDays, 913);
      expect(e.totalOwed, 5478);
    });

    test('S4: deemed mode uses asOf when not yet regular', () {
      final e = estimateQaza(
        QazaInputs(
          gender: Gender.male,
          birthDate: DateTime(2000, 3, 15),
          bulughMode: BulughMode.deemed,
        ),
        asOf: DateTime(2026, 8, 11),
      );
      expect(e.bulughDate, DateTime(2014, 10, 4));
      expect(e.gapDays, 4329);
      expect(e.owedDays, 4329);
    });

    test('S5: cautious female with 50% prayed → 2486 owed each', () {
      final e = estimateQaza(
        QazaInputs(
          gender: Gender.female,
          birthDate: DateTime(2000, 3, 15),
          bulughMode: BulughMode.cautious,
          prayedFraction: 0.5,
        ),
        asOf: DateTime(2026, 8, 11),
      );
      expect(e.bulughDate, DateTime(2008, 12, 7));
      expect(e.gapDays, 6456);
      expect(e.haydDeduction, closeTo(1484.625, 0.01));
      expect(e.owedDays, 2486);
    });

    test('S6: witr off → 5 prayer types, total 18260', () {
      final e = estimateQaza(QazaInputs(
        gender: Gender.male,
        birthDate: DateTime(1995, 6, 1),
        bulughMode: BulughMode.remembered,
        rememberedBulughDate: DateTime(2010, 1, 1),
        regularSince: DateTime(2020, 1, 1),
        includeWitr: false,
      ));
      expect(e.perPrayer.length, 5);
      expect(e.perPrayer.containsKey(PrayerKeys.witr), isFalse);
      expect(e.totalOwed, 18260);
    });

    test('S7: bulugh after gap end → zero everywhere, never negative', () {
      final e = estimateQaza(QazaInputs(
        gender: Gender.male,
        birthDate: DateTime(2015, 1, 1),
        bulughMode: BulughMode.remembered,
        rememberedBulughDate: DateTime(2030, 1, 1),
        regularSince: DateTime(2020, 1, 1),
      ));
      expect(e.gapDays, 0);
      expect(e.owedDays, 0);
      expect(e.totalOwed, 0);
    });

    test('S8: deductions larger than gap → clamped to zero', () {
      final e = estimateQaza(QazaInputs(
        gender: Gender.female,
        birthDate: DateTime(1995, 6, 1),
        bulughMode: BulughMode.remembered,
        rememberedBulughDate: DateTime(2020, 1, 1),
        regularSince: DateTime(2020, 1, 31),
        births: 3, // 120 nifas days > 30-day gap
      ));
      expect(e.gapDays, 30);
      expect(e.obligatedDays, 0.0);
      expect(e.owedDays, 0);
    });

    test('perPrayer keys are the canonical prayer keys', () {
      final e = estimateQaza(
        QazaInputs(
          gender: Gender.male,
          birthDate: DateTime(2000, 1, 1),
          bulughMode: BulughMode.deemed,
        ),
        asOf: DateTime(2026, 8, 11),
      );
      expect(e.perPrayer.keys.toList(), PrayerKeys.six);
    });
  });
}
