import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_design_tokens.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.goldenYellow,
      onPrimary: AppColors.darkCharcoal,
      secondary: AppColors.brandRed,
      onSecondary: Colors.white,
      error: AppColors.brandRed,
      onError: Colors.white,
      surface: AppColors.surfaceWhite,
      onSurface: AppColors.darkCharcoal,
      surfaceContainerLowest: AppColors.creamBackground,
      surfaceContainerLow: AppColors.creamBackground,
      surfaceContainer: AppColors.surfaceWhite,
      surfaceContainerHigh: AppColors.creamBackground,
      surfaceContainerHighest: AppColors.goldTint,
      outline: AppColors.softBorder,
      outlineVariant: AppColors.softBorder,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.creamBackground,
      extensions: const [AppDesignTokens.light],
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkCharcoal,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColors.darkCharcoal,
        indicatorColor: AppColors.goldenYellow,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceWhite,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
          side: const BorderSide(color: AppColors.softBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.goldenYellow,
          foregroundColor: AppColors.darkCharcoal,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(AppDesignTokens.minTouchTarget, AppDesignTokens.minTouchTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.goldenYellow,
          foregroundColor: AppColors.darkCharcoal,
          minimumSize: const Size(AppDesignTokens.minTouchTarget, AppDesignTokens.minTouchTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkCharcoal,
          minimumSize: const Size(AppDesignTokens.minTouchTarget, AppDesignTokens.minTouchTarget),
          side: const BorderSide(color: AppColors.softBorder, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
          side: const BorderSide(color: AppColors.softBorder, width: 1),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppDesignTokens.radius12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
          borderSide: const BorderSide(color: AppColors.softBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
          borderSide: const BorderSide(color: AppColors.softBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
          borderSide: const BorderSide(color: AppColors.goldenYellow, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
          borderSide: const BorderSide(color: AppColors.brandRed, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      iconTheme: const IconThemeData(
        color: AppColors.darkCharcoal,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.darkCharcoal, height: 1.2),
        headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.darkCharcoal, height: 1.25),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.darkCharcoal, height: 1.25),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.darkCharcoal, height: 1.4),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.darkCharcoal, height: 1.4),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.darkCharcoal, height: 1.4),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.mutedBrown, height: 1.3),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.darkCharcoal, height: 1.4),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.mutedBrown, height: 1.3),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.mutedBrown, height: 1.3),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.softBorder,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.darkCharcoal,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDesignTokens.radius8)),
      ),
    );
  }
}
