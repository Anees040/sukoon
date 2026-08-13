import 'dart:async';
import 'dart:math' as math;

import 'package:sensors_plus/sensors_plus.dart';

import 'package:sukoon/qibla/qibla_math.dart';

/// Tilt-compensated compass built on raw accelerometer + magnetometer
/// (sensors_plus). We deliberately avoid heavier compass plugins — this
/// keeps the dependency tree small (size budget) and the math visible.
///
/// Emits smoothed headings in degrees from magnetic north [0, 360).
/// Adds error 'no_sensor' when the device lacks usable sensors.
class CompassService {
  static const _alpha = 0.34; // Smoother magnetic baseline
  static const _vecAlpha = 0.42; // Stable LPF without heavy lag
  static const _magCorrection = 0.11; // Softer correction, less snap-back
  static const _sensorTimeout = Duration(seconds: 3);

  Stream<double> headingStream() {
    late StreamController<double> controller;
    StreamSubscription<AccelerometerEvent>? accSub;
    StreamSubscription<MagnetometerEvent>? magSub;
    StreamSubscription<GyroscopeEvent>? gyroSub;
    Timer? firstEventTimer;

    double? ax, ay, az;
    double? mx, my, mz;
    double? sMagSmooth, cMagSmooth;
    double? headingEstimate;
    double? lastEmitHeading;
    int? lastGyroUs;
    var gotAny = false;
    var errored = false;

    void fail() {
      if (errored || controller.isClosed) return;
      errored = true;
      controller.addError('no_sensor');
    }

    void emitHeadingIfNeeded(double value) {
      if (controller.isClosed) return;
      if (lastEmitHeading != null &&
          angleDelta(lastEmitHeading!, value).abs() < 0.05) {
        return;
      }
      lastEmitHeading = value;
      controller.add(normalizeDegrees(value));
    }

    void onGyro(GyroscopeEvent g) {
      if (headingEstimate == null || controller.isClosed) return;
      final nowUs = DateTime.now().microsecondsSinceEpoch;
      if (lastGyroUs == null) {
        lastGyroUs = nowUs;
        return;
      }
      final dt = (nowUs - lastGyroUs!) / 1000000.0;
      lastGyroUs = nowUs;
      if (dt <= 0 || dt > 0.25) return;

      // Positive z rotates CCW; heading from north increases clockwise.
      // Slightly scale down gyro contribution for calmer motion.
      final deltaDeg = -(g.z * 180.0 / math.pi) * dt * 0.80;
      headingEstimate = normalizeDegrees(headingEstimate! + deltaDeg);
      emitHeadingIfNeeded(headingEstimate!);
    }

    void onMag(MagnetometerEvent m) {
      if (ax == null || controller.isClosed) return;
      gotAny = true;

      // Low-pass magnetometer readings.
      mx = mx == null ? m.x : mx! + _vecAlpha * (m.x - mx!);
      my = my == null ? m.y : my! + _vecAlpha * (m.y - my!);
      mz = mz == null ? m.z : mz! + _vecAlpha * (m.z - mz!);
      if (mx == null || my == null || mz == null) return;

      // Android SensorManager.getRotationMatrix, reduced to azimuth:
      // H = E × A (magnetic × gravity), M = A × H, azimuth = atan2(Hy, My).
      final ex = mx!, ey = my!, ez = mz!;
      final gx = ax!, gy = ay!, gz = az!;

      var hx = ey * gz - ez * gy;
      var hy = ez * gx - ex * gz;
      var hz = ex * gy - ey * gx;
      final normH = math.sqrt(hx * hx + hy * hy + hz * hz);
      if (normH < 0.1) return; // device in freefall / bad reading
      hx /= normH;
      hy /= normH;
      hz /= normH;

      final normA = math.sqrt(gx * gx + gy * gy + gz * gz);
      if (normA < 0.1) return;
      final axn = gx / normA;
      final azn = gz / normA;

      // M = A × H
      final myv = azn * hx - axn * hz;

      final azimuth = math.atan2(hy, myv);

      // Circular EMA on magnetic absolute heading.
      final s = math.sin(azimuth), c = math.cos(azimuth);
      sMagSmooth =
          sMagSmooth == null ? s : _alpha * s + (1 - _alpha) * sMagSmooth!;
      cMagSmooth =
          cMagSmooth == null ? c : _alpha * c + (1 - _alpha) * cMagSmooth!;

      final magHeading = normalizeDegrees(
        math.atan2(sMagSmooth!, cMagSmooth!) * 180.0 / math.pi,
      );

      if (headingEstimate == null) {
        headingEstimate = magHeading;
      } else {
        // Complementary correction keeps gyro drift bounded while remaining snappy.
        headingEstimate = normalizeDegrees(
          headingEstimate! + angleDelta(headingEstimate!, magHeading) * _magCorrection,
        );
      }
      emitHeadingIfNeeded(headingEstimate!);
    }

    controller = StreamController<double>(
      onListen: () {
        firstEventTimer = Timer(_sensorTimeout, () {
          if (!gotAny) fail();
        });
        try {
          accSub = accelerometerEventStream().listen(
            (e) {
              // Low-pass gravity vector.
              ax = ax == null ? e.x : ax! + _vecAlpha * (e.x - ax!);
              ay = ay == null ? e.y : ay! + _vecAlpha * (e.y - ay!);
              az = az == null ? e.z : az! + _vecAlpha * (e.z - az!);
            },
            onError: (Object _) => fail(),
            cancelOnError: false,
          );
          magSub = magnetometerEventStream().listen(
            onMag,
            onError: (Object _) => fail(),
            cancelOnError: false,
          );
          gyroSub = gyroscopeEventStream().listen(
            onGyro,
            onError: (Object _) {},
            cancelOnError: false,
          );
        } catch (_) {
          fail();
        }
      },
      onCancel: () async {
        firstEventTimer?.cancel();
        await accSub?.cancel();
        await magSub?.cancel();
        await gyroSub?.cancel();
      },
    );

    return controller.stream;
  }

  /// True when recent headings scatter too much — the classic symptom of a
  /// magnetometer that needs a figure-8 calibration. Uses the circular
  /// resultant length R (1.0 = perfectly steady, 0 = pure noise).
  static bool isNoisy(List<double> recentHeadings) {
    if (recentHeadings.length < 10) return false;
    var sSum = 0.0, cSum = 0.0;
    for (final h in recentHeadings) {
      final r = h * math.pi / 180.0;
      sSum += math.sin(r);
      cSum += math.cos(r);
    }
    final n = recentHeadings.length;
    final resultant =
        math.sqrt((sSum / n) * (sSum / n) + (cSum / n) * (cSum / n));
    return resultant < 0.85;
  }
}
