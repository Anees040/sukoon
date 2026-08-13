import 'package:flutter/material.dart';

import 'package:sukoon/constants.dart';
import 'package:sukoon/core/locale_controller.dart';
import 'package:sukoon/features/shell/app_shell.dart';
import 'package:sukoon/l10n/gen/app_localizations.dart';
import 'package:sukoon/theme.dart';

class SukoonApp extends StatelessWidget {
  const SukoonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleController.instance,
      builder: (context, _) {
        return MaterialApp(
          title: AppInfo.appName,
          debugShowCheckedModeBanner: false,
          locale: LocaleController.instance.locale, // null = follow system
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: buildSukoonTheme(isUrdu: false),
          // Re-theme below the resolved locale so Urdu gets its taller
          // line-height and ur font-fallback hint.
          builder: (context, child) {
            final isUr =
                Localizations.localeOf(context).languageCode == 'ur';
            return Theme(
              data: buildSukoonTheme(isUrdu: isUr),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const AppShell(),
        );
      },
    );
  }
}
