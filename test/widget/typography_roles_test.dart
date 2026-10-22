import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ny_kitchen_app/core/theme/app_design_tokens.dart';
import 'package:ny_kitchen_app/core/theme/app_theme.dart';

void main() {
  group('Typography Roles & Font Resolution Test', () {
    test('AppTypography definitions declare intended family, weights, and features', () {
      // 1. Figure role: Display family, bold/w700/w800, tabular figures
      expect(AppTypography.figureHero.fontFamily, equals('SpaceGrotesk'));
      expect(AppTypography.figureHero.fontWeight, equals(FontWeight.w800));
      expect(AppTypography.figureHero.fontFeatures, contains(const FontFeature.tabularFigures()));

      expect(AppTypography.figure.fontFamily, equals('SpaceGrotesk'));
      expect(AppTypography.figure.fontWeight, equals(FontWeight.w700));
      expect(AppTypography.figure.fontFeatures, contains(const FontFeature.tabularFigures()));

      // 2. Heading role: Display family, weight 600
      expect(AppTypography.heading.fontFamily, equals('SpaceGrotesk'));
      expect(AppTypography.heading.fontWeight, equals(FontWeight.w600));

      // 3. Button role: Display family, weight 600
      expect(AppTypography.button.fontFamily, equals('SpaceGrotesk'));
      expect(AppTypography.button.fontWeight, equals(FontWeight.w600));

      // 4. Body role: Body family (Inter), 14px, weight 400
      expect(AppTypography.body.fontFamily, equals('Inter'));
      expect(AppTypography.body.fontWeight, equals(FontWeight.w400));
      expect(AppTypography.body.fontSize, equals(14.0));

      // 5. Label role: Body family (Inter), weight 600, letter spacing +0.5
      expect(AppTypography.label.fontFamily, equals('Inter'));
      expect(AppTypography.label.fontWeight, equals(FontWeight.w600));
      expect(AppTypography.label.letterSpacing, equals(0.5));
    });

    testWidgets('Theme renders all five typography roles with resolved families and weights', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Column(
              children: const [
                Text('₱575.00', key: Key('role_figure_hero'), style: AppTypography.figureHero),
                Text('₱335.00', key: Key('role_figure'), style: AppTypography.figure),
                Text('Sales Trend', key: Key('role_heading'), style: AppTypography.heading),
                Text('View all', key: Key('role_button'), style: AppTypography.button),
                Text('Chicken Inasal', key: Key('role_body'), style: AppTypography.body),
                Text('QUICK ACTIONS', key: Key('role_label'), style: AppTypography.label),
              ],
            ),
          ),
        ),
      );

      final heroText = tester.widget<Text>(find.byKey(const Key('role_figure_hero')));
      expect(heroText.style?.fontFamily, equals('SpaceGrotesk'));
      expect(heroText.style?.fontWeight, equals(FontWeight.w800));

      final figText = tester.widget<Text>(find.byKey(const Key('role_figure')));
      expect(figText.style?.fontFamily, equals('SpaceGrotesk'));
      expect(figText.style?.fontWeight, equals(FontWeight.w700));

      final headingText = tester.widget<Text>(find.byKey(const Key('role_heading')));
      expect(headingText.style?.fontFamily, equals('SpaceGrotesk'));
      expect(headingText.style?.fontWeight, equals(FontWeight.w600));

      final buttonText = tester.widget<Text>(find.byKey(const Key('role_button')));
      expect(buttonText.style?.fontFamily, equals('SpaceGrotesk'));
      expect(buttonText.style?.fontWeight, equals(FontWeight.w600));

      final bodyText = tester.widget<Text>(find.byKey(const Key('role_body')));
      expect(bodyText.style?.fontFamily, equals('Inter'));
      expect(bodyText.style?.fontWeight, equals(FontWeight.w400));

      final labelText = tester.widget<Text>(find.byKey(const Key('role_label')));
      expect(labelText.style?.fontFamily, equals('Inter'));
      expect(labelText.style?.fontWeight, equals(FontWeight.w600));
      expect(labelText.style?.letterSpacing, equals(0.5));
    });
  });
}
