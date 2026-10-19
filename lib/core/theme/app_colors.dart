import 'package:flutter/material.dart';

/// Single source of truth for color tokens across the N.Y Kitchen POS app.
/// Strictly adheres to the Visual Polish Specification.
class AppColors {
  // Brand & Core Surfaces
  static const Color darkCharcoal = Color(0xFF2B241A);   // Nav rail, app bar, primary text
  static const Color goldenYellow = Color(0xFFFFCA05);   // CTA fill, active tab, selected state
  static const Color goldDeep = Color(0xFFE0B000);       // Pressed/hover on gold (tactile 3D bottom edge)
  static const Color goldInk = Color(0xFF7A5B00);        // Gold-toned text or links on light surfaces
  static const Color brandRed = Color(0xFFD9271C);       // Destructive actions and errors only
  static const Color forest = Color(0xFF2E7D4F);         // Success, paid, synced, in stock
  static const Color inkBlue = Color(0xFF2F6F8F);        // Info, syncing
  static const Color goldTint = Color(0xFFFFF1C2);       // Warning surface (low stock, pending sync)
  static const Color creamBackground = Color(0xFFF5F6F8);// Page surface (crisp light-neutral surface, replaces #FFF8E7)
  static const Color pageBackground = creamBackground;
  static const Color lightBackground = creamBackground;
  static const Color surfaceWhite = Color(0xFFFFFFFF);   // Flat cards
  static const Color softBorder = Color(0xFFE7DCCB);     // 1px flat card borders and dividers
  static const Color mutedBrown = Color(0xFF6B5E4B);     // Secondary text
  static const Color disabled = Color(0xFFB9AE9B);       // Disabled controls only

  // Tactile 3D Depth Edges
  static const Color goldTactileEdge = goldDeep;
  static const Color cardTactileEdge = softBorder;
  static const Color destructiveTactileEdge = Color(0xFFB31B12);

  // Backward-compatibility aliases for existing codebase references
  static const Color primarySeed = goldenYellow;
  static const Color tertiary = goldInk;
  static const Color success = forest;
  static const Color info = inkBlue;
  static const Color mutedText = mutedBrown;
  static const Color brandTint = goldTint;
  static const Color successSurface = Color(0xFFE8F5E9);

  // Card shadow placeholder (kept for smooth backward compatibility where elevation might be referenced)
  static const Color cardShadow = Color(0x00000000); // Transparent; cards use 1px softBorder
}
