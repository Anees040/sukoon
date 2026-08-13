import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'package:sukoon/core/prefs.dart';
import 'package:sukoon/data/city_repository.dart';

/// Best-effort one-shot coarse location.
///
/// Philosophy (offline + privacy):
/// - Location is OPTIONAL — the app always works from the saved city.
/// - One coarse reading, snapped to the nearest bundled city so the label
///   stays human ("Lahore", not "31.52, 74.35"). Nothing leaves the phone.
/// - Never throws; any failure returns false and the saved city stays.
class LocationService {
  LocationService._();

  /// Refreshes lat/lng + label from GPS. Returns true on success.
  ///
  /// When [silent] is true we never invoke the OS permission dialog — we only
  /// use access that was already granted. Used at first launch so the location
  /// prompt is never stacked on top of the DND primer; GPS stays opt-in from
  /// Settings, where [refresh] is called with [silent] false to actively ask.
  static Future<bool> refresh({bool silent = false}) async {
    // Native geolocation only matters on the Android build; in previews
    // (web/desktop) we silently keep the saved city.
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return false;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && !silent) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return false;
      }

      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 10),
          ),
        );
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
      }
      if (pos == null) return false;

      // Snap to the nearest bundled city for a human-readable label.
      final cities = await CityRepository.all();
      City? nearest;
      var best = double.infinity;
      for (final c in cities) {
        final d = _approxDistance(pos.latitude, pos.longitude, c.lat, c.lng);
        if (d < best) {
          best = d;
          nearest = c;
        }
      }

      await Prefs.setLocation(
        pos.latitude,
        pos.longitude,
        nearest?.nameEn ?? Prefs.locationLabel,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Equirectangular approximation — plenty accurate for nearest-city
  /// snapping within Pakistan, and much cheaper than haversine.
  static double _approxDistance(
      double lat1, double lng1, double lat2, double lng2) {
    final x = (lng2 - lng1) * math.cos((lat1 + lat2) * math.pi / 360.0);
    final y = lat2 - lat1;
    return x * x + y * y;
  }
}
