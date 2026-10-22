import 'package:baglanti_agi/app/theme/tokens.dart';
import 'package:flutter/material.dart';

ThemeData buildTheme() {
  const scheme = ColorScheme.dark(
    surface: Palette.asphalt,
    onSurface: Palette.paper,
    primary: Palette.yellow,
    onPrimary: Palette.ink,
    secondary: Palette.blue,
    onSecondary: Palette.ink,
    error: Palette.red,
    onError: Palette.ink,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Palette.asphalt,
    fontFamily: Fonts.ui,
    splashFactory: NoSplash.splashFactory,
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Palette.paper, fontSize: 15),
      bodySmall: TextStyle(color: Palette.textMuted, fontSize: 13),
    ),
    focusColor: Palette.yellow,
    inputDecorationTheme: const InputDecorationTheme(
      border: InputBorder.none,
      isDense: true,
      contentPadding: EdgeInsets.zero,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Palette.ink,
      selectionColor: Color(0x66FBBC04),
    ),
  );
}
