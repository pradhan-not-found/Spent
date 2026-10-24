import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Spent palette: Atlas's neutral ink on white, with the logo's orange as the brand.
abstract final class C {
  static const page = Color(0xFFECECEC);
  static const screen = Color(0xFFFFFFFF);
  static const pill = Color(0xFFF0F0F0);
  static const ink = Color(0xFF111111);
  static const inkMuted = Color(0xFF6B6B6B);
  static const inkFaint = Color(0xFFA3A3A3);
  static const brand = Color(0xFFFA5A0A);
  static const brandSoft = Color(0xFFF28A5A);
  static const sky = Color(0xFF36C5FF);
  static const skySoft = Color(0xFF7CB8FF);
  static const mint = Color(0xFF1FB574);
  static const mintSoft = Color(0xFF6FD9A3);
  static const income = Color(0xFF1A9E63);
  static const gray = Color(0xFFA6A6A6);
  static const graySoft = Color(0xFFBDBDBD);
}

const softShadow = [
  BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1)),
  BoxShadow(color: Color(0x1A000000), blurRadius: 24, spreadRadius: -6, offset: Offset(0, 8)),
];

/// Switzer is a variable font, so weight is set through the `wght` axis as well.
TextStyle t(double size, FontWeight weight, {Color color = C.ink, double? height, double tracking = -0.2}) =>
    TextStyle(
      fontFamily: 'Switzer',
      fontFamilyFallback: const ['SpentFallback'],
      fontSize: size,
      fontWeight: weight,
      fontVariations: [FontVariation('wght', weight.value.toDouble())],
      color: color,
      height: height,
      letterSpacing: tracking,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

ThemeData buildTheme() => ThemeData(
      useMaterial3: true,
      fontFamily: 'Switzer',
      fontFamilyFallback: const ['SpentFallback'],
      scaffoldBackgroundColor: C.screen,
      colorScheme: ColorScheme.fromSeed(seedColor: C.brand, primary: C.brand, surface: C.screen),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {for (final p in TargetPlatform.values) p: const CupertinoPageTransitionsBuilder()},
      ),
    );
