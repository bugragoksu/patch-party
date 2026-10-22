import 'package:flutter/material.dart';

/// Design tokens from docs/specs/04-design.md §2 ("Çıkartma Atölyesi").
abstract final class Palette {
  static const asphalt = Color(0xFF1C1B1F);
  static const asphaltRaised = Color(0xFF26242A);
  static const line = Color(0xFF3A373F);
  static const paper = Color(0xFFF6F4EE);
  static const ink = Color(0xFF141414);
  static const inkMuted = Color(0xFF4A4640);
  static const textMuted = Color(0xFFB9B4AA);
  static const blue = Color(0xFF4285F4);
  static const green = Color(0xFF34A853);
  static const yellow = Color(0xFFFBBC04);
  static const red = Color(0xFFEA4335);
}

abstract final class Fonts {
  static const display = 'Unbounded';
  static const ui = 'GoogleSansFlex';
  static const code = 'GoogleSansCode';
}

abstract final class Stroke {
  static const width = 3.0;
}

abstract final class Radii {
  static const button = 16.0;
  static const card = 22.0;
  static const big = 28.0;
}

abstract final class Motion {
  static const stamp = Duration(milliseconds: 420);
  static const pop = Duration(milliseconds: 300);
  static const popStagger = Duration(milliseconds: 120);
  static const sweep = Duration(milliseconds: 1600);
  static const pulse = Duration(milliseconds: 1200);

  /// Overshoot used by "stamp": 1.25 -> 0.94 -> 1.
  static const stampCurve = Cubic(0.2, 0.9, 0.3, 1.2);
}

abstract final class TextStyles {
  static const display = TextStyle(
    fontFamily: Fonts.display,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
    height: 1.05,
  );
  static const title = TextStyle(
    fontFamily: Fonts.display,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );
  static const ui = TextStyle(fontFamily: Fonts.ui, height: 1.4);
  static const code = TextStyle(
    fontFamily: Fonts.code,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
  );
  static const label = TextStyle(
    fontFamily: Fonts.ui,
    fontWeight: FontWeight.w700,
    fontSize: 11,
    letterSpacing: 1.3,
  );
}

Color clusterColor(int argb) => Color(argb);
