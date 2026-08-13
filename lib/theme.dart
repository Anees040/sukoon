import 'package:flutter/material.dart';

/// Sukoon Gold design tokens — derived from the Sukoon logo palette.
/// Rules: dark only · deep teal-black surfaces · warm gold accent ·
/// sage green for success/streaks · NO blue · no loud gradients.
///
/// Palette (from the brand mark):
///   deep teal black #011519 · warm gold #EDB24E · champagne #F9D47B
///   golden brown #C78225 · forest green #19352B · sage #576B4A
///   warm ivory #FCEFB5
class SukoonColors {
  static const bg = Color(0xFF011519); // deep teal black
  static const surface = Color(0xFF062328);
  static const card = Color(0xFF0A2F36);
  static const cardRaised = Color(0xFF104049);
  static const stroke = Color(0xFF1D5560);

  static const accent = Color(0xFFEDB24E); // warm gold
  static const accentHi = Color(0xFFF9D47B); // champagne highlight
  static const accentDim = Color(0xFF4A3816); // gold selection fill
  static const goldDeep = Color(0xFFC78225); // golden brown depth

  static const forest = Color(0xFF19352B); // deep forest green
  static const lime = Color(0xFF8BAF7A); // bright sage (success/streak)
  static const limeDim = Color(0xFF2E4A33); // sage selection fill

  static const text = Color(0xFFF7EFD9); // warm ivory (softened)
  static const ivory = Color(0xFFFCEFB5); // brand highlight
  static const textSecondary = Color(0xFFA9BBA8); // sage-gray
  static const textFaint = Color(0xFF64806F);

  static const danger = Color(0xFFE07A5F); // terracotta — no harsh red
  static const warning = Color(0xFFF9D47B); // champagne
}

/// Bundled Urdu font (assets/fonts/). Declared as a fallback on EVERY style
/// so Urdu city names render even in the English locale, and as the primary
/// family when the ur locale is active. Noto Nastaliq Urdu = proper Nastaliq
/// script for Pakistani readers. Until the .ttf is dropped into assets/fonts/
/// and the pubspec `fonts:` stanza is uncommented, this name simply falls back
/// to the system Urdu font (no crash). See assets/fonts/FONTS.md.
const kUrduFontFamily = 'NotoNastaliqUrdu';
const kUrduFallback = [kUrduFontFamily];

/// Builds the app theme. [isUrdu] switches to the Arabic-script font and
/// increases line-height so Urdu script never clips.
ThemeData buildSukoonTheme({required bool isUrdu}) {
  final height = isUrdu ? 1.9 : 1.3;
  const urduLocale = Locale('ur');

  TextStyle style(double size, FontWeight w, {Color c = SukoonColors.text}) =>
      TextStyle(
        fontSize: size,
        fontWeight: w,
        color: c,
        height: height,
        fontFamily: isUrdu ? kUrduFontFamily : null,
        fontFamilyFallback: kUrduFallback,
        locale: isUrdu ? urduLocale : null,
      );

  final textTheme = TextTheme(
    displayLarge: style(46, FontWeight.w700),
    displayMedium: style(34, FontWeight.w700),
    displaySmall: style(28, FontWeight.w700),
    headlineMedium: style(26, FontWeight.w700),
    headlineSmall: style(22, FontWeight.w600),
    titleLarge: style(20, FontWeight.w600),
    titleMedium: style(16, FontWeight.w600),
    titleSmall: style(14, FontWeight.w600),
    bodyLarge: style(16, FontWeight.w400),
    bodyMedium: style(14, FontWeight.w400),
    bodySmall: style(12, FontWeight.w400, c: SukoonColors.textSecondary),
    labelLarge: style(15, FontWeight.w600),
    labelMedium: style(12, FontWeight.w500, c: SukoonColors.textSecondary),
    labelSmall: style(11, FontWeight.w500, c: SukoonColors.textFaint),
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: SukoonColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: SukoonColors.accent,
      onPrimary: Color(0xFF241A05),
      secondary: SukoonColors.lime,
      onSecondary: Color(0xFF101F12),
      surface: SukoonColors.surface,
      onSurface: SukoonColors.text,
      surfaceContainerHighest: SukoonColors.card,
      error: SukoonColors.danger,
      onError: Color(0xFF2A0E08),
      outline: SukoonColors.stroke,
    ),
  );

  return base.copyWith(
    textTheme: textTheme,
    dividerColor: SukoonColors.stroke,
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: SukoonColors.accent),
    appBarTheme: const AppBarTheme(
      backgroundColor: SukoonColors.bg,
      foregroundColor: SukoonColors.text,
      elevation: 0,
      centerTitle: false,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: SukoonColors.surface,
      indicatorColor: SukoonColors.accentDim,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? SukoonColors.accent
              : SukoonColors.textSecondary,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => textTheme.labelMedium!.copyWith(
          color: states.contains(WidgetState.selected)
              ? SukoonColors.text
              : SukoonColors.textSecondary,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: SukoonColors.cardRaised,
      contentTextStyle: textTheme.bodyMedium,
      actionTextColor: SukoonColors.accent,
      behavior: SnackBarBehavior.floating,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? SukoonColors.accent
            : SukoonColors.textFaint,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? SukoonColors.accentDim
            : SukoonColors.card,
      ),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: SukoonColors.accent,
      inactiveTrackColor: SukoonColors.card,
      thumbColor: SukoonColors.accent,
      overlayColor: Color(0x29EDB24E),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: SukoonColors.card,
      selectedColor: SukoonColors.accentDim,
      side: const BorderSide(color: SukoonColors.stroke),
      labelStyle: textTheme.labelLarge,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: SukoonColors.accent,
        foregroundColor: const Color(0xFF241A05),
        textStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: SukoonColors.accent),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: SukoonColors.text,
        side: const BorderSide(color: SukoonColors.stroke),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: SukoonColors.accentDim,
        selectedForegroundColor: SukoonColors.text,
        foregroundColor: SukoonColors.textSecondary,
        side: const BorderSide(color: SukoonColors.stroke),
      ),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: SukoonColors.surface,
      headerBackgroundColor: SukoonColors.card,
      dayForegroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? const Color(0xFF241A05)
            : SukoonColors.text,
      ),
      dayBackgroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? SukoonColors.accent
            : null,
      ),
      todayForegroundColor:
          const WidgetStatePropertyAll(SukoonColors.accent),
    ),
    timePickerTheme: const TimePickerThemeData(
      backgroundColor: SukoonColors.surface,
      dialHandColor: SukoonColors.accent,
    ),
  );
}

/// Standard corner radius for cards/sheets.
const kRadius = 18.0;

/// Standard screen padding.
const kScreenPad = EdgeInsets.fromLTRB(16, 8, 16, 24);
