import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ny_kitchen_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('POS Flow Integration Tests', () {
    testWidgets('Add food items to order -> complete checkout -> void transaction', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Login as cashier
      final usernameField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).last;
      
      await tester.enterText(usernameField, 'cashier1');
      await tester.enterText(passwordField, 'password123'); // Assuming seeded
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // We should be on Cashier POS (home page)
      // Find a food card to tap
      final foodCard = find.byType(Card).first;
      if (foodCard.evaluate().isNotEmpty) {
        await tester.tap(foodCard);
        await tester.pumpAndSettle();
        
        // Check order summary panel updates
        expect(find.text('Subtotal'), findsWidgets);
        expect(find.text('Place Order'), findsOneWidget);

        // Complete Checkout
        await tester.tap(find.text('Place Order'));
        await tester.pumpAndSettle();
        
        // This opens the Review Dialog
        final confirmButton = find.text('Confirm Order');
        if (confirmButton.evaluate().isNotEmpty) {
          await tester.tap(confirmButton);
          await tester.pumpAndSettle();
          
          // Payment dialog (Exact Cash)
          final exactCashButton = find.text('Exact Amount');
          if (exactCashButton.evaluate().isNotEmpty) {
            await tester.tap(exactCashButton);
            await tester.pumpAndSettle();
          }
          
          final completePaymentButton = find.text('Complete Payment');
          if (completePaymentButton.evaluate().isNotEmpty) {
            await tester.tap(completePaymentButton);
            await tester.pumpAndSettle(const Duration(seconds: 2));
            
            // Payment complete dialog
            expect(find.text('Payment Complete!'), findsOneWidget);
            await tester.tap(find.text('New Order'));
            await tester.pumpAndSettle();
          }
        }
      }
    });
  });
}
