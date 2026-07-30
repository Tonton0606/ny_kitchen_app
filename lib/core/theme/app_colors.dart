import 'package:flutter/material.dart';

class AppColors {
  static const Color primarySeed = Color(0xFFFFB300);
  static const Color tertiary = Color(0xFF7C5800);
  static const Color success = Color(0xFF2E7D32);
  static const Color info = Color(0xFF1565C0);

  // Login branding tokens derived from the official logo.
  static const Color goldenYellow = Color(0xFFFFCA05);
  static const Color brandRed = Color(0xFFD9271C);
  static const Color creamBackground = Color(0xFFFFF8E7);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color darkCharcoal = Color(0xFF2B241A);
  static const Color mutedText = Color(0xFF6F675C);
  static const Color softBorder = Color(0xFFE7DCCB);
  static const Color brandTint = Color(0xFFFFF3C4);
  static const Color successSurface = Color(0xFFE8F5E9);

  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [creamBackground, surfaceWhite],
  );

  static const Color cardShadow = Color(0x1A000000); // 10% black
}
