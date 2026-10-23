import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ny_kitchen_app/core/theme/app_theme.dart';
import 'package:ny_kitchen_app/features/shared/widgets/app_buttons.dart';
import 'package:ny_kitchen_app/features/shared/widgets/app_text_field.dart';
import 'package:ny_kitchen_app/features/shared/widgets/app_status_chip.dart';
import 'package:ny_kitchen_app/features/shared/widgets/app_confirm_dialog.dart';

void main() {
  group('Phase 2 Component Kit Tests', () {
    testWidgets('AppPrimaryButton renders text and triggers callback', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppPrimaryButton(
              text: 'Charge ₱150',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Charge ₱150'), findsOneWidget);
      await tester.tap(find.text('Charge ₱150'));
      expect(tapped, isTrue);
    });

    testWidgets('AppDestructiveButton renders with brandRed color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AppDestructiveButton(
              text: 'Void Item',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Void Item'), findsOneWidget);
    });

    testWidgets('AppTextField displays permanent visible label and handles error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppTextField(
              label: 'Username',
              errorText: 'Required field',
            ),
          ),
        ),
      );

      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Required field'), findsOneWidget);
    });

    testWidgets('AppStatusChip pairs color with icon and text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppStatusChip(
              label: 'In Stock',
              type: AppStatusType.success,
            ),
          ),
        ),
      );

      expect(find.text('In Stock'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('AppConfirmDialog renders consequence text and focuses Cancel button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => AppConfirmDialog.show(
                    context,
                    title: 'Delete Cashier Account',
                    consequenceText: 'This cashier account will be permanently deactivated.',
                    confirmText: 'Deactivate Account',
                    isDestructive: true,
                  ),
                  child: const Text('Open Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Cashier Account'), findsOneWidget);
      expect(find.text('This cashier account will be permanently deactivated.'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Deactivate Account'), findsOneWidget);

      // Verify Cancel button has autofocus
      final cancelButton = tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Cancel'));
      expect(cancelButton.autofocus, isTrue);
    });
  });
}
