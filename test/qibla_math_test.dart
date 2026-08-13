import 'package:flutter_test/flutter_test.dart';
import 'package:sukoon/constants.dart';
import 'package:sukoon/qibla/qibla_math.dart';

/// Bearing expectations independently verified with the Python great-circle
/// formula (tool/verify_math.py) and cross-checked against published qibla
/// directions for Pakistani cities (all roughly west, 250–270°).
void main() {
  group('normalizeDegrees', () {
    test('wraps into [0, 360)', () {
      expect(normalizeDegrees(0), 0);
      expect(normalizeDegrees(360), 0);
      expect(normalizeDegrees(-90), 270);
      expect(normalizeDegrees(765), 45);
    });
  });

  group('qiblaBearing', () {
    test('Islamabad ≈ 255.9°', () {
      expect(qiblaBearing(33.6844, 73.0479), closeTo(255.91, 2.0));
    });

    test('Karachi ≈ 267.7°', () {
      expect(qiblaBearing(24.8607, 67.0011), closeTo(267.74, 2.0));
    });

    test('Lahore ≈ 260.4°', () {
      expect(qiblaBearing(31.5204, 74.3587), closeTo(260.37, 2.0));
    });

    test('Peshawar ≈ 254.0°', () {
      expect(qiblaBearing(34.0151, 71.5249), closeTo(253.99, 2.0));
    });

    test('standing at the Kaaba → bearing is defined (no NaN)', () {
      final b = qiblaBearing(Kaaba.lat, Kaaba.lng);
      expect(b.isNaN, isFalse);
      expect(b, inInclusiveRange(0.0, 360.0));
    });
  });

  group('angleDelta (needle animation shortest path)', () {
    test('350° → 10° rotates +20°, not −340°', () {
      expect(angleDelta(350, 10), closeTo(20, 1e-9));
    });

    test('10° → 350° rotates −20°', () {
      expect(angleDelta(10, 350), closeTo(-20, 1e-9));
    });

    test('opposite directions rotate +180°', () {
      expect(angleDelta(0, 180), closeTo(180, 1e-9));
      expect(angleDelta(90, 270), closeTo(180, 1e-9));
    });

    test('no rotation → 0', () {
      expect(angleDelta(42, 42), closeTo(0, 1e-9));
    });
  });
}
