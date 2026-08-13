import 'package:flutter/material.dart';

import 'package:sukoon/core/prefs.dart';

/// App locale switcher: 'system' | 'en' | 'ur'. Persisted in Prefs.
class LocaleController extends ChangeNotifier {
  LocaleController._();

  static final LocaleController instance = LocaleController._();

  String get mode => Prefs.localeMode;

  /// null = follow system locale.
  Locale? get locale => switch (mode) {
        'en' => const Locale('en'),
        'ur' => const Locale('ur'),
        _ => null,
      };

  Future<void> set(String newMode) async {
    await Prefs.setLocaleMode(newMode);
    notifyListeners();
  }
}
