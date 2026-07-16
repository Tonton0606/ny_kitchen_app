import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: AppColors.light.primary,
      onPrimary: AppColors.light.onPrimary,
      primaryContainer: AppColors.light.primaryContainer,
      secondary: AppColors.light.secondary,
      onSecondary: AppColors.light.onSecondary,
      error: AppColors.light.error,
      onError: AppColors.light.onError,
      surface: AppColors.light.surface,
      onSurface: AppColors.light.onSurface,
      onSurfaceVariant: AppColors.light.onSurfaceVariant,
      outlineVariant: AppColors.light.outlineVariant,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.light.bg,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.light.surfaceContainer,
        foregroundColor: AppColors.light.onSurface,
        elevation: 0,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.light.surface,
        indicatorColor: AppColors.light.primaryContainer,
      ),
      cardTheme: CardThemeData(
        color: AppColors.light.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.light.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.light.primary,
          foregroundColor: AppColors.light.onPrimary,
          disabledBackgroundColor: AppColors.light.primary.withValues(alpha: 0.12),
          disabledForegroundColor: AppColors.light.onSurface.withValues(alpha: 0.38),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.light.primary,
          foregroundColor: AppColors.light.onPrimary,
          disabledBackgroundColor: AppColors.light.primary.withValues(alpha: 0.12),
          disabledForegroundColor: AppColors.light.onSurface.withValues(alpha: 0.38),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.light.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.light.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.light.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.light.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: BorderSide(color: AppColors.light.outlineVariant),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.normal, height: 1.12),
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, height: 1.25),
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.25),
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.25),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 1.27),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.5),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, height: 1.43),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, height: 1.43),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.43),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 1.33),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, height: 1.45),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.light.outlineVariant.withValues(alpha: 0.4),
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.dark(
      primary: AppColors.dark.primary,
      onPrimary: AppColors.dark.onPrimary,
      primaryContainer: AppColors.dark.primaryContainer,
      secondary: AppColors.dark.secondary,
      onSecondary: AppColors.dark.onSecondary,
      error: AppColors.dark.error,
      onError: AppColors.dark.onError,
      surface: AppColors.dark.surface,
      onSurface: AppColors.dark.onSurface,
      onSurfaceVariant: AppColors.dark.onSurfaceVariant,
      outlineVariant: AppColors.dark.outlineVariant,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.dark.bg,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.dark.surfaceContainer,
        foregroundColor: AppColors.dark.onSurface,
        elevation: 0,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.dark.surface,
        indicatorColor: AppColors.dark.primaryContainer,
      ),
      cardTheme: CardThemeData(
        color: AppColors.dark.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.dark.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.dark.primary,
          foregroundColor: AppColors.dark.onPrimary,
          disabledBackgroundColor: AppColors.dark.primary.withValues(alpha: 0.12),
          disabledForegroundColor: AppColors.dark.onSurface.withValues(alpha: 0.38),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.dark.primary,
          foregroundColor: AppColors.dark.onPrimary,
          disabledBackgroundColor: AppColors.dark.primary.withValues(alpha: 0.12),
          disabledForegroundColor: AppColors.dark.onSurface.withValues(alpha: 0.38),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.dark.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.dark.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.dark.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.dark.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: BorderSide(color: AppColors.dark.outlineVariant),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.normal, height: 1.12),
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, height: 1.25),
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.25),
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.25),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 1.27),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.5),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, height: 1.43),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, height: 1.43),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.43),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 1.33),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, height: 1.45),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.dark.outlineVariant.withValues(alpha: 0.4),
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
