import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ny_kitchen_app/features/admin/presentation/pages/food_management_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mockCategories = [
    {
      'id': 1,
      'name': 'Pastil Special',
      'icon_url': '🍛',
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    },
  ];

  final mockFoods = [
    {
      'id': 101,
      'category_id': 1,
      'category_name': 'Pastil Special',
      'name': 'Special Pastil Rice',
      'price': 85.0,
      'image_path': '',
      'availability': 'available',
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    },
  ];

  testWidgets('FoodManagementPage opens right panel for Add Food and row selection', (tester) async {
    tester.view.physicalSize = const Size(1440, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FoodManagementPage(
            enableAutoRefresh: false,
            initialFoods: mockFoods,
            initialCategories: mockCategories,
          ),
        ),
      ),
    );
    await tester.pump();

    // 1. Verify main page elements
    expect(find.text('Food Management'), findsWidgets);
    expect(find.text('Add Food'), findsWidgets);

    // 2. Click "Add Food" -> Right panel appears with "Add Food Item"
    await tester.tap(find.text('Add Food').first);
    await tester.pump();

    expect(find.text('Add Food Item'), findsWidgets);
    expect(find.text('Save Food Item'), findsOneWidget);

    // 3. Close the right panel
    await tester.tap(find.byTooltip('Close panel'));
    await tester.pump();
    expect(find.text('Save Food Item'), findsNothing);

    // 4. Click row for "Special Pastil Rice"
    expect(find.text('Special Pastil Rice'), findsOneWidget);
    await tester.tap(find.text('Special Pastil Rice'));
    await tester.pump();

    // 5. Right panel opens with Food Information and Edit Food Item button
    expect(find.text('Food Information'), findsOneWidget);
    expect(find.text('Edit Food Item'), findsOneWidget);
    expect(find.text('₱85.00'), findsWidgets);

    // 6. Click "Edit Food Item" -> Switches right panel to Edit Food Item mode
    await tester.tap(find.text('Edit Food Item'));
    await tester.pump();

    expect(find.text('Save Changes'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    // 7. Click Cancel -> Returns to Food Information
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    expect(find.text('Food Information'), findsOneWidget);
    expect(find.text('Edit Food Item'), findsOneWidget);

    // 8. Close the panel
    await tester.tap(find.byTooltip('Close panel'));
    await tester.pump();
    expect(find.text('Food Information'), findsNothing);
  });

  testWidgets('FoodManagementPage paginates 10 items per page with page controls', (tester) async {
    tester.view.physicalSize = const Size(1440, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final twentyFiveFoods = List.generate(25, (i) {
      final numStr = (i + 1).toString().padLeft(2, '0');
      return {
        'id': 200 + i,
        'category_id': 1,
        'category_name': 'Pastil Special',
        'name': 'Food Item $numStr',
        'price': 50.0 + i,
        'image_path': '',
        'availability': 'available',
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
      };
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FoodManagementPage(
            enableAutoRefresh: false,
            initialFoods: twentyFiveFoods,
            initialCategories: mockCategories,
          ),
        ),
      ),
    );
    await tester.pump();

    // Page 1: Items 1 to 10
    expect(find.text('Showing 1–10 of 25 items'), findsOneWidget);
    expect(find.text('Food Item 01'), findsOneWidget);
    expect(find.text('Food Item 10'), findsOneWidget);
    expect(find.text('Food Item 11'), findsNothing);

    // Tap "Next page" button
    await tester.tap(find.byTooltip('Next page'));
    await tester.pump();

    // Page 2: Items 11 to 20
    expect(find.text('Showing 11–20 of 25 items'), findsOneWidget);
    expect(find.text('Food Item 01'), findsNothing);
    expect(find.text('Food Item 11'), findsOneWidget);
    expect(find.text('Food Item 20'), findsOneWidget);
    expect(find.text('Food Item 21'), findsNothing);

    // Tap page button "3"
    await tester.tap(find.text('3'));
    await tester.pump();

    // Page 3: Items 21 to 25
    expect(find.text('Showing 21–25 of 25 items'), findsOneWidget);
    expect(find.text('Food Item 21'), findsOneWidget);
    expect(find.text('Food Item 25'), findsOneWidget);

    // Tap "Previous page" button
    await tester.tap(find.byTooltip('Previous page'));
    await tester.pump();

    // Back to Page 2
    expect(find.text('Showing 11–20 of 25 items'), findsOneWidget);
    expect(find.text('Food Item 11'), findsOneWidget);
  });
}
