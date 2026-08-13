import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// English and Urdu ARB files must stay in lockstep — a key missing from
/// app_ur.arb silently falls back to English at runtime, which is exactly
/// the kind of bug reviewers in Pakistan will notice immediately.
Set<String> baseKeys(Map<String, dynamic> arb) =>
    arb.keys.where((k) => !k.startsWith('@')).toSet();

Set<String> placeholders(String value) => RegExp(r'\{(\w+)\}')
    .allMatches(value)
    .map((m) => m.group(1)!)
    .toSet();

void main() {
  late Map<String, dynamic> en;
  late Map<String, dynamic> ur;

  setUpAll(() {
    en = jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
        as Map<String, dynamic>;
    ur = jsonDecode(File('lib/l10n/app_ur.arb').readAsStringSync())
        as Map<String, dynamic>;
  });

  test('same message keys in both languages', () {
    final enKeys = baseKeys(en);
    final urKeys = baseKeys(ur);
    expect(
      urKeys.difference(enKeys),
      isEmpty,
      reason: 'ur has keys en lacks',
    );
    expect(
      enKeys.difference(urKeys),
      isEmpty,
      reason: 'en has keys ur lacks (Urdu fallback bug!)',
    );
  });

  test('placeholders match per key', () {
    for (final k in baseKeys(en)) {
      expect(
        placeholders(ur[k] as String),
        placeholders(en[k] as String),
        reason: 'placeholder mismatch in "$k"',
      );
    }
  });

  test('metadata entries reference real keys', () {
    for (final k in en.keys.where(
      (k) => k.startsWith('@') && !k.startsWith('@@'),
    )) {
      expect(
        en.containsKey(k.substring(1)),
        isTrue,
        reason: '$k has no matching message',
      );
    }
  });

  test('locales declared correctly', () {
    expect(en['@@locale'], 'en');
    expect(ur['@@locale'], 'ur');
  });
}
