import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ny_kitchen_app/features/shared/widgets/state_placeholders.dart';

void main() {
  group('StatePlaceholders Widget Tests', () {
    testWidgets('empty shows icon and message', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => StatePlaceholders.empty(
                message: 'No data found', 
                icon: Icons.inbox, 
                context: context
              ),
            ),
          ),
        ),
      );

      expect(find.text('No data found'), findsOneWidget);
      expect(find.byIcon(Icons.inbox), findsOneWidget);
    });

    testWidgets('error shows error icon and message', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => StatePlaceholders.error(
                message: 'Failed to load',
                context: context,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Failed to load'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('loading shows CircularProgressIndicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => StatePlaceholders.loading(context: context),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
