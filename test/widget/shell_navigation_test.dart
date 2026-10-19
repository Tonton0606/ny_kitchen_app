import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ny_kitchen_app/core/theme/app_theme.dart';
import 'package:ny_kitchen_app/features/shared/widgets/app_status_strip.dart';
import 'package:ny_kitchen_app/features/cashier/presentation/widgets/navigation/cashier_nav_rail.dart';
import 'package:ny_kitchen_app/features/admin/presentation/widgets/navigation/admin_nav_rail.dart';
import 'package:ny_kitchen_app/features/cashier/presentation/widgets/navigation/cashier_bottom_nav.dart';

void main() {
  Widget buildTestableWidget(Widget child, {double width = 1024, double height = 768}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: SizedBox(
          width: width,
          height: height,
          child: child,
        ),
      ),
    );
  }

  group('AppStatusStrip Widget Tests', () {
    testWidgets('renders title, clock, and settings callback on wide screen', (tester) async {
      bool settingsTapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          AppStatusStrip(
            title: 'Point of Sale',
            onSettingsTap: () => settingsTapped = true,
          ),
          width: 1200,
        ),
      );
      await tester.pump();

      expect(find.text('Point of Sale'), findsOneWidget);
      expect(find.text('Online'), findsOneWidget);
      expect(find.text('Cloud Synced'), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsOneWidget);

      final settingsBtn = find.byTooltip('Settings');
      expect(settingsBtn, findsOneWidget);
      await tester.tap(settingsBtn);
      expect(settingsTapped, isTrue);
    });

    testWidgets('renders cleanly on narrow width without overflow', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const AppStatusStrip(title: 'Orders'),
          width: 360,
        ),
      );
      await tester.pump();

      expect(find.text('Orders'), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Nav Rail Visual Tests', () {
    testWidgets('CashierNavRail renders active indicators and role badge', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          CashierNavRail(
            selectedIndex: 0,
            isExpanded: true,
            onToggleExpand: (_) {},
            onDestinationSelected: (_) {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('CASHIER'), findsOneWidget);
      expect(find.text('Shift Active'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Orders'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
    });

    testWidgets('AdminNavRail renders active indicators and role badge', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          AdminNavRail(
            selectedIndex: 0,
            isExpanded: true,
            onToggleExpand: (_) {},
            onDestinationSelected: (_) {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('ADMINISTRATOR'), findsOneWidget);
      expect(find.text('Full System Access'), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Sales Reports'), findsOneWidget);
      expect(find.text('Food Management'), findsOneWidget);
    });
  });

  group('CashierBottomNav Tests', () {
    testWidgets('CashierBottomNav renders navigation items with labels', (tester) async {
      int selected = 0;
      await tester.pumpWidget(
        buildTestableWidget(
          CashierBottomNav(
            selectedIndex: selected,
            onItemSelected: (idx) => selected = idx,
          ),
          width: 400,
          height: 80,
        ),
      );
      await tester.pump();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Orders'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);

      await tester.tap(find.text('Orders'));
      expect(selected, 1);
    });
  });
}
