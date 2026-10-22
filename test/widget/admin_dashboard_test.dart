import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ny_kitchen_app/features/admin/presentation/pages/admin_dashboard_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('AdminDashboardPage renders Quick Actions with navigation triggers', (tester) async {
    int? navigatedIndex;

    tester.view.physicalSize = const Size(1440, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdminDashboardPage(
            onNavigate: (index) {
              navigatedIndex = index;
            },
          ),
        ),
      ),
    );
    await tester.pump();

    // Verify Quick Actions card title is removed (slim row without title)
    expect(find.text('Quick Actions'), findsNothing);

    // Verify all 4 action items exist
    expect(find.text('Add Food Item'), findsOneWidget);
    expect(find.text('Register Staff'), findsOneWidget);
    expect(find.text('Sales Reports'), findsOneWidget);
    expect(find.text('Backup & Sync'), findsOneWidget);

    // Tap 'Add Food Item' -> Should navigate to index 2 (Food Management)
    await tester.tap(find.text('Add Food Item'));
    await tester.pump();
    expect(navigatedIndex, 2);

    // Tap 'Register Staff' -> Should navigate to index 3 (Account Management)
    await tester.tap(find.text('Register Staff'));
    await tester.pump();
    expect(navigatedIndex, 3);

    // Tap 'Sales Reports' -> Should navigate to index 1 (Sales Reports)
    await tester.tap(find.text('Sales Reports'));
    await tester.pump();
    expect(navigatedIndex, 1);

    // Tap 'Backup & Sync' -> Should navigate to index 5 (Backup & Restore)
    await tester.tap(find.text('Backup & Sync'));
    await tester.pump();
    expect(navigatedIndex, 5);
  });

  testWidgets('AdminDashboardPage does not render Open POS or duplicate settings icons', (tester) async {
    tester.view.physicalSize = const Size(1440, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AdminDashboardPage(),
        ),
      ),
    );
    await tester.pump();

    // Verify Open POS button does not exist anywhere on the dashboard
    expect(find.text('Open POS'), findsNothing);
    // Verify duplicate User Settings icon is removed from the dashboard
    expect(find.byTooltip('User Settings'), findsNothing);
  });
}
