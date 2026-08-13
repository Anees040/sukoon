import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Sanity checks on the bundled offline city list. Runs with dart:io
/// (flutter test executes from the package root).
void main() {
  late List<Map<String, dynamic>> cities;

  setUpAll(() {
    final raw = File('assets/data/pk_cities.json').readAsStringSync();
    cities = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  });

  test('has a healthy number of cities', () {
    expect(cities.length, greaterThanOrEqualTo(90));
  });

  test('ids are unique, names present in both languages', () {
    final ids = <String>{};
    for (final c in cities) {
      expect(
        ids.add(c['id'] as String),
        isTrue,
        reason: 'duplicate id: ${c['id']}',
      );
      expect((c['name_en'] as String).trim(), isNotEmpty,
          reason: '${c['id']} name_en');
      expect((c['name_ur'] as String).trim(), isNotEmpty,
          reason: '${c['id']} name_ur');
    }
  });

  test('coordinates are inside Pakistan\'s bounding box', () {
    for (final c in cities) {
      final lat = (c['lat'] as num).toDouble();
      final lng = (c['lng'] as num).toDouble();
      expect(lat, inInclusiveRange(23.0, 37.5), reason: '${c['id']} lat=$lat');
      expect(lng, inInclusiveRange(60.0, 78.0), reason: '${c['id']} lng=$lng');
    }
  });

  test('major cities and northern/AJK coverage are present', () {
    final ids = cities.map((c) => c['id']).toSet();
    for (final must in [
      'karachi',
      'lahore',
      'islamabad',
      'rawalpindi',
      'peshawar',
      'quetta',
      'multan',
      'faisalabad',
      'gilgit',
      'skardu',
      'muzaffarabad',
      'gwadar',
    ]) {
      expect(ids.contains(must), isTrue, reason: 'missing $must');
    }
  });

  test('first entry is Karachi (population order preserved)', () {
    expect(cities.first['id'], 'karachi');
  });
}
