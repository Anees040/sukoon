import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// A Pakistani city with bilingual names (offline dataset).
class City {
  const City({
    required this.id,
    required this.nameEn,
    required this.nameUr,
    required this.lat,
    required this.lng,
  });

  final String id;
  final String nameEn;
  final String nameUr;
  final double lat;
  final double lng;

  factory City.fromJson(Map<String, dynamic> json) => City(
        id: json['id'] as String,
        nameEn: json['name_en'] as String,
        nameUr: json['name_ur'] as String,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
      );
}

/// Loads and searches the bundled city list (assets/data/pk_cities.json).
/// The list ships sorted by population — keep that order for display.
class CityRepository {
  CityRepository._();

  static List<City>? _cache;

  static Future<List<City>> all() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/data/pk_cities.json');
    final list = (jsonDecode(raw) as List<dynamic>)
        .map((e) => City.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    _cache = list;
    return list;
  }

  /// Case-insensitive match on either language. Empty query → everything.
  static List<City> search(List<City> cities, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return cities;
    return [
      for (final c in cities)
        if (c.nameEn.toLowerCase().contains(q) || c.nameUr.contains(q)) c,
    ];
  }

  static City? byId(List<City> cities, String id) {
    for (final c in cities) {
      if (c.id == id) return c;
    }
    return null;
  }
}
