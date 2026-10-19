import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ny_kitchen_app/core/theme/app_colors.dart';
import 'package:ny_kitchen_app/core/theme/app_design_tokens.dart';
import 'package:ny_kitchen_app/core/theme/app_theme.dart';

void main() {
  group('AppDesignTokens & AppTheme Tests', () {
    test('Tokens contain exact brand palette colors', () {
      const tokens = AppDesignTokens.light;
      expect(tokens.darkCharcoal, const Color(0xFF2B241A));
      expect(tokens.goldenYellow, const Color(0xFFFFCA05));
      expect(tokens.goldDeep, const Color(0xFFE0B000));
      expect(tokens.goldInk, const Color(0xFF7A5B00));
      expect(tokens.brandRed, const Color(0xFFD9271C));
      expect(tokens.forest, const Color(0xFF2E7D4F));
      expect(tokens.inkBlue, const Color(0xFF2F6F8F));
      expect(tokens.goldTint, const Color(0xFFFFF1C2));
      expect(tokens.creamBackground, const Color(0xFFF5F6F8));
      expect(tokens.surfaceWhite, const Color(0xFFFFFFFF));
      expect(tokens.softBorder, const Color(0xFFE7DCCB));
      expect(tokens.mutedBrown, const Color(0xFF6B5E4B));
      expect(tokens.disabled, const Color(0xFFB9AE9B));
    });

    test('Tokens contain tactile 3D depth and layout constraints', () {
      const tokens = AppDesignTokens.light;
      expect(tokens.tactilePressOffset, 1.5);
      expect(tokens.tactileEdgeThickness, 2.0);
      expect(tokens.goldTactileEdge, AppColors.goldDeep);

      // Radii: 8 and 12 only
      expect(AppDesignTokens.radius8, 8.0);
      expect(AppDesignTokens.radius12, 12.0);

      // Touch targets
      expect(AppDesignTokens.minTouchTarget, 48.0);
      expect(AppDesignTokens.primaryActionTouchTarget, 56.0);
    });

    testWidgets('AppTheme registers AppDesignTokens extension in context', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) {
              final tokens = context.tokens;
              expect(tokens, isNotNull);
              expect(tokens.darkCharcoal, AppColors.darkCharcoal);
              expect(tokens.goldenYellow, AppColors.goldenYellow);
              return Scaffold(
                backgroundColor: tokens.creamBackground,
                body: Container(),
              );
            },
          ),
        ),
      );
    });

    test('AppTypography provides tabular figures for monetary amounts', () {
      final style = AppTypography.tabularPrice();
      expect(style.fontFeatures, isNotNull);
      expect(style.fontFeatures!.any((f) => f.feature == 'tnum'), isTrue);
    });
  });
}
