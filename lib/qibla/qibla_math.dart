import 'dart:math' as math;

import 'package:sukoon/constants.dart';

/// Pure spherical math for the qibla — no Flutter imports, unit-testable.

double _rad(double deg) => deg * math.pi / 180.0;
double _deg(double rad) => rad * 180.0 / math.pi;

/// Normalizes any angle to [0, 360).
double normalizeDegrees(double d) {
  final r = d % 360.0;
  return r < 0 ? r + 360.0 : r;
}

/// Initial great-circle bearing from point 1 → point 2, degrees from
/// true north (0..360).
double bearingBetween({
  required double lat1,
  required double lng1,
  required double lat2,
  required double lng2,
}) {
  final phi1 = _rad(lat1);
  final phi2 = _rad(lat2);
  final dLng = _rad(lng2 - lng1);
  final y = math.sin(dLng) * math.cos(phi2);
  final x = math.cos(phi1) * math.sin(phi2) -
      math.sin(phi1) * math.cos(phi2) * math.cos(dLng);
  return normalizeDegrees(_deg(math.atan2(y, x)));
}

/// Bearing to the Kaaba from the given location.
/// Islamabad ≈ 256°, Karachi ≈ 268°, Lahore ≈ 260° (west-ish for Pakistan).
double qiblaBearing(double lat, double lng) => bearingBetween(
      lat1: lat,
      lng1: lng,
      lat2: Kaaba.lat,
      lng2: Kaaba.lng,
    );

/// Signed shortest rotation from [from] to [to] in degrees, in (-180, 180].
/// Use this to animate needles without the 359°→0° spin glitch.
double angleDelta(double from, double to) {
  var d = (to - from) % 360.0;
  if (d > 180.0) d -= 360.0;
  if (d <= -180.0) d += 360.0;
  return d;
}
