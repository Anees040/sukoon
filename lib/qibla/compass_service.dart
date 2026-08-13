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
  static const _alpha = 0.15; // EMA factor — stable but responsive
  static const _sensorTimeout = Duration(seconds: 3);

  Stream<double> headingStream() {
    late StreamController<double> controller;
    StreamSubscription<AccelerometerEvent>? accSub;
    StreamSubscription<MagnetometerEvent>? magSub;
    Timer? firstEventTimer;

    double? ax, ay, az;
    double? sSmooth, cSmooth;
    var gotAny = false;
    var errored = false;

    void fail() {
      if (errored || controller.isClosed) return;
      errored = true;
      controller.addError('no_sensor');
    }

    void onMag(MagnetometerEvent m) {
      if (ax == null || controller.isClosed) return;
      gotAny = true;

      // Android SensorManager.getRotationMatrix, reduced to azimuth:
      // H = E × A (magnetic × gravity), M = A × H, azimuth = atan2(Hy, My).
      final ex = m.x, ey = m.y, ez = m.z;
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
      final axn = gx / normA, azn = gz / normA;

      // M = A × H — only the y component is needed for azimuth.
      final my = azn * hx - axn * hz;

      final azimuth = math.atan2(hy, my);

      // Circular EMA (smooth sin/cos separately to survive the 360→0 wrap).
      final s = math.sin(azimuth), c = math.cos(azimuth);
      sSmooth = sSmooth == null ? s : _alpha * s + (1 - _alpha) * sSmooth!;
      cSmooth = cSmooth == null ? c : _alpha * c + (1 - _alpha) * cSmooth!;

      final heading =
          normalizeDegrees(math.atan2(sSmooth!, cSmooth!) * 180.0 / math.pi);
      controller.add(heading);
    }

    controller = StreamController<double>(
      onListen: () {
        firstEventTimer = Timer(_sensorTimeout, () {
          if (!gotAny) fail();
        });
        try {
          accSub = accelerometerEventStream().listen(
            (e) {
              ax = e.x;
              ay = e.y;
              az = e.z;
            },
            onError: (Object _) => fail(),
            cancelOnError: false,
          );
          magSub = magnetometerEventStream().listen(
            onMag,
            onError: (Object _) => fail(),
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
