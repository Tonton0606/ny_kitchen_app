import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Type-safe Flutter ThemeExtension providing unified design system tokens
/// across all roles (Cashier & Admin) in the N.Y Kitchen POS application.
class AppDesignTokens extends ThemeExtension<AppDesignTokens> {
  // Brand Color Tokens
  final Color darkCharcoal;
  final Color goldenYellow;
  final Color goldDeep;
  final Color goldInk;
  final Color brandRed;
  final Color forest;
  final Color inkBlue;
  final Color goldTint;
  final Color creamBackground;
  final Color surfaceWhite;
  final Color softBorder;
  final Color mutedBrown;
  final Color disabled;

  // Tactile 3D Depth Tokens
  final Color goldTactileEdge;
  final Color cardTactileEdge;
  final Color destructiveTactileEdge;
  final double tactilePressOffset;
  final double tactileEdgeThickness;

  // Spacing Tokens
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;

  // Corner Radii Tokens
  static const double radius8 = 8.0;   // inputs, chips, buttons
  static const double radius12 = 12.0; // cards, dialogs, modals
  static final BorderRadius borderRadius8 = BorderRadius.circular(radius8);
  static final BorderRadius borderRadius12 = BorderRadius.circular(radius12);

  // Touch Target Tokens
  static const double minTouchTarget = 48.0;
  static const double primaryActionTouchTarget = 56.0;

  // Motion Tokens
  static const Duration motionFast = Duration(milliseconds: 120);
  static const Duration motionMedium = Duration(milliseconds: 180);

  const AppDesignTokens({
    required this.darkCharcoal,
    required this.goldenYellow,
    required this.goldDeep,
    required this.goldInk,
    required this.brandRed,
    required this.forest,
    required this.inkBlue,
    required this.goldTint,
    required this.creamBackground,
    required this.surfaceWhite,
    required this.softBorder,
    required this.mutedBrown,
    required this.disabled,
    required this.goldTactileEdge,
    required this.cardTactileEdge,
    required this.destructiveTactileEdge,
    this.tactilePressOffset = 1.5,
    this.tactileEdgeThickness = 2.0,
  });

  /// Default Light Theme Tokens instance
  static const AppDesignTokens light = AppDesignTokens(
    darkCharcoal: AppColors.darkCharcoal,
    goldenYellow: AppColors.goldenYellow,
    goldDeep: AppColors.goldDeep,
    goldInk: AppColors.goldInk,
    brandRed: AppColors.brandRed,
    forest: AppColors.forest,
    inkBlue: AppColors.inkBlue,
    goldTint: AppColors.goldTint,
    creamBackground: AppColors.creamBackground,
    surfaceWhite: AppColors.surfaceWhite,
    softBorder: AppColors.softBorder,
    mutedBrown: AppColors.mutedBrown,
    disabled: AppColors.disabled,
    goldTactileEdge: AppColors.goldTactileEdge,
    cardTactileEdge: AppColors.cardTactileEdge,
    destructiveTactileEdge: AppColors.destructiveTactileEdge,
    tactilePressOffset: 1.5,
    tactileEdgeThickness: 2.0,
  );

  @override
  ThemeExtension<AppDesignTokens> copyWith({
    Color? darkCharcoal,
    Color? goldenYellow,
    Color? goldDeep,
    Color? goldInk,
    Color? brandRed,
    Color? forest,
    Color? inkBlue,
    Color? goldTint,
    Color? creamBackground,
    Color? surfaceWhite,
    Color? softBorder,
    Color? mutedBrown,
    Color? disabled,
    Color? goldTactileEdge,
    Color? cardTactileEdge,
    Color? destructiveTactileEdge,
    double? tactilePressOffset,
    double? tactileEdgeThickness,
  }) {
    return AppDesignTokens(
      darkCharcoal: darkCharcoal ?? this.darkCharcoal,
      goldenYellow: goldenYellow ?? this.goldenYellow,
      goldDeep: goldDeep ?? this.goldDeep,
      goldInk: goldInk ?? this.goldInk,
      brandRed: brandRed ?? this.brandRed,
      forest: forest ?? this.forest,
      inkBlue: inkBlue ?? this.inkBlue,
      goldTint: goldTint ?? this.goldTint,
      creamBackground: creamBackground ?? this.creamBackground,
      surfaceWhite: surfaceWhite ?? this.surfaceWhite,
      softBorder: softBorder ?? this.softBorder,
      mutedBrown: mutedBrown ?? this.mutedBrown,
      disabled: disabled ?? this.disabled,
      goldTactileEdge: goldTactileEdge ?? this.goldTactileEdge,
      cardTactileEdge: cardTactileEdge ?? this.cardTactileEdge,
      destructiveTactileEdge: destructiveTactileEdge ?? this.destructiveTactileEdge,
      tactilePressOffset: tactilePressOffset ?? this.tactilePressOffset,
      tactileEdgeThickness: tactileEdgeThickness ?? this.tactileEdgeThickness,
    );
  }

  @override
  ThemeExtension<AppDesignTokens> lerp(ThemeExtension<AppDesignTokens>? other, double t) {
    if (other is! AppDesignTokens) return this;
    return AppDesignTokens(
      darkCharcoal: Color.lerp(darkCharcoal, other.darkCharcoal, t)!,
      goldenYellow: Color.lerp(goldenYellow, other.goldenYellow, t)!,
      goldDeep: Color.lerp(goldDeep, other.goldDeep, t)!,
      goldInk: Color.lerp(goldInk, other.goldInk, t)!,
      brandRed: Color.lerp(brandRed, other.brandRed, t)!,
      forest: Color.lerp(forest, other.forest, t)!,
      inkBlue: Color.lerp(inkBlue, other.inkBlue, t)!,
      goldTint: Color.lerp(goldTint, other.goldTint, t)!,
      creamBackground: Color.lerp(creamBackground, other.creamBackground, t)!,
      surfaceWhite: Color.lerp(surfaceWhite, other.surfaceWhite, t)!,
      softBorder: Color.lerp(softBorder, other.softBorder, t)!,
      mutedBrown: Color.lerp(mutedBrown, other.mutedBrown, t)!,
      disabled: Color.lerp(disabled, other.disabled, t)!,
      goldTactileEdge: Color.lerp(goldTactileEdge, other.goldTactileEdge, t)!,
      cardTactileEdge: Color.lerp(cardTactileEdge, other.cardTactileEdge, t)!,
      destructiveTactileEdge: Color.lerp(destructiveTactileEdge, other.destructiveTactileEdge, t)!,
      tactilePressOffset: lerpDouble(tactilePressOffset, other.tactilePressOffset, t)!,
      tactileEdgeThickness: lerpDouble(tactileEdgeThickness, other.tactileEdgeThickness, t)!,
    );
  }
}

/// Helper extension on BuildContext to quickly access tokens via `context.tokens`
extension AppDesignTokensContextX on BuildContext {
  AppDesignTokens get tokens => Theme.of(this).extension<AppDesignTokens>() ?? AppDesignTokens.light;
}

/// Typography helper for tabular figures (prices, quantities, timers)
class AppTypography {
  static const TextStyle display = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.darkCharcoal,
    height: 1.2,
  );

  static const TextStyle title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.darkCharcoal,
    height: 1.25,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.darkCharcoal,
    height: 1.4,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.darkCharcoal,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.mutedBrown,
    height: 1.3,
  );

  /// Tabular figure styling for monetary values and currency displays
  static TextStyle tabularPrice({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w700,
    Color color = AppColors.darkCharcoal,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  // Admin & POS Standardized Typography Scale
  static const TextStyle pageTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
    color: AppColors.darkCharcoal,
  );

  static const TextStyle pageSubtitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.mutedText,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: AppColors.darkCharcoal,
  );

  static const TextStyle kpiHeroValue = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.6,
    color: AppColors.darkCharcoal,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle metricValue = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    color: AppColors.darkCharcoal,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle metricLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.mutedText,
  );

  static const TextStyle tableHeader = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
    color: AppColors.mutedText,
  );

  static const TextStyle tableCellPrimary = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.darkCharcoal,
  );

  static const TextStyle tableCellSecondary = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.darkCharcoal,
  );

  static const TextStyle badgeLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle dialogTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.darkCharcoal,
  );
}
