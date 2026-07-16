import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const LightColors light = LightColors();
  static const DarkColors dark = DarkColors();

  static const Color success = Color(0xFF2E7D32);
  static const Color info = Color(0xFF1565C0);
}

class LightColors {
  const LightColors();

  final Color bg = const Color(0xFFFFF8F2);
  final Color surface = const Color(0xFFFFFFFF);
  final Color surfaceContainer = const Color(0xFFFFF0E6);
  final Color primary = const Color(0xFFB85C1E);
  final Color onPrimary = const Color(0xFFFFFFFF);
  final Color primaryContainer = const Color(0xFFFFDEC7);
  final Color secondary = const Color(0xFF2E7D32);
  final Color onSecondary = const Color(0xFFFFFFFF);
  final Color error = const Color(0xFFBA1A1A);
  final Color onError = const Color(0xFFFFFFFF);
  final Color onSurface = const Color(0xFF1F1B16);
  final Color onSurfaceVariant = const Color(0xFF645B52);
  final Color outlineVariant = const Color(0xFFE8DED4);
}

class DarkColors {
  const DarkColors();

  final Color bg = const Color(0xFF141210);
  final Color surface = const Color(0xFF1F1B16);
  final Color surfaceContainer = const Color(0xFF2B2722);
  final Color primary = const Color(0xFFFFB77C);
  final Color onPrimary = const Color(0xFF442300);
  final Color primaryContainer = const Color(0xFF8D3F00);
  final Color secondary = const Color(0xFF6CD86C);
  final Color onSecondary = const Color(0xFF003A00);
  final Color error = const Color(0xFFFFB4AB);
  final Color onError = const Color(0xFF690005);
  final Color onSurface = const Color(0xFFEAE1D9);
  final Color onSurfaceVariant = const Color(0xFFCEC4BA);
  final Color outlineVariant = const Color(0xFF5A5149);
}
