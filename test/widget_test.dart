import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:ny_kitchen_app/features/auth/presentation/pages/login_page.dart';
import 'package:ny_kitchen_app/core/theme/app_theme.dart';
import 'package:ny_kitchen_app/features/cashier/presentation/widgets/navigation/cashier_nav_rail.dart';
import 'package:ny_kitchen_app/features/admin/presentation/widgets/navigation/admin_nav_rail.dart';

void main() {
  Widget buildApp() {
    return MaterialApp(theme: AppTheme.lightTheme, home: const LoginPage());
  }

  void setScreen(WidgetTester tester, double width, double height) {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1.0;
  }

  tearDown(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  // ── Layout tests ────────────────────────────────────────────────────────

  group('Responsive layout — no Flutter exceptions', () {
    for (final size in [
      const Size(320, 700),
      const Size(360, 800),
      const Size(600, 960),
      const Size(800, 600),
      const Size(900, 700),
      const Size(1024, 768),
      const Size(1200, 800),
      const Size(1440, 900),
    ]) {
      testWidgets(
        '${size.width.toInt()}×${size.height.toInt()} renders without exceptions',
        (WidgetTester tester) async {
          setScreen(tester, size.width, size.height);
          await tester.pumpWidget(buildApp());
          await tester.pump();
          expect(tester.takeException(), isNull);
        },
      );
    }
  });

  group('Content — phone layout (<600dp)', () {
    testWidgets('Does not show promotional panel on phone', (
      WidgetTester tester,
    ) async {
      setScreen(tester, 360, 800);
      await tester.pumpWidget(buildApp());
      await tester.pump();

      expect(find.text('One counter.\nEvery order, tracked.'), findsNothing);
      expect(find.text('#00482'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('Content — desktop layout (>=1200dp)', () {
    testWidgets('Shows promotional headline on desktop', (
      WidgetTester tester,
    ) async {
      setScreen(tester, 1200, 800);
      await tester.pumpWidget(buildApp());
      await tester.pump();

      expect(find.text('One counter.\nEvery order, tracked.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Shows sample order card on desktop', (
      WidgetTester tester,
    ) async {
      setScreen(tester, 1200, 800);
      await tester.pumpWidget(buildApp());
      await tester.pump();

      expect(find.text('#00482'), findsOneWidget);
      expect(find.text('Sisig Rice'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Login form presence', () {
    testWidgets('Welcome back heading is present', (WidgetTester tester) async {
      setScreen(tester, 800, 1000);
      await tester.pumpWidget(buildApp());
      await tester.pump();

      expect(find.text('Welcome back'), findsOneWidget);
    });

    testWidgets('Email and password fields are present', (
      WidgetTester tester,
    ) async {
      setScreen(tester, 800, 1000);
      await tester.pumpWidget(buildApp());
      await tester.pump();

      expect(
        find.widgetWithText(TextField, 'Email or username'),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);
    });

    testWidgets('Remember Me is present', (WidgetTester tester) async {
      setScreen(tester, 800, 1000);
      await tester.pumpWidget(buildApp());
      await tester.pump();

      expect(find.text('Remember Me'), findsOneWidget);
    });

    testWidgets('Forgot Password is present', (WidgetTester tester) async {
      setScreen(tester, 800, 1000);
      await tester.pumpWidget(buildApp());
      await tester.pump();

      expect(find.text('Forgot Password?'), findsOneWidget);
    });

    testWidgets('Official logo is rendered', (WidgetTester tester) async {
      setScreen(tester, 800, 1000);
      await tester.pumpWidget(buildApp());
      await tester.pump();

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Image &&
              w.image is AssetImage &&
              (w.image as AssetImage).assetName ==
                  'assets/images/branding/ny_kitchen_logo.png',
        ),
        findsWidgets,
      );
    });

    testWidgets('Role selector is absent', (WidgetTester tester) async {
      setScreen(tester, 800, 1000);
      await tester.pumpWidget(buildApp());
      await tester.pump();

      expect(find.text('Login as Admin'), findsNothing);
      expect(find.text('Login as Cashier'), findsNothing);
    });
  });

  group('Functional tests', () {
    testWidgets('Password visibility toggle works', (
      WidgetTester tester,
    ) async {
      setScreen(tester, 800, 1000);
      await tester.pumpWidget(buildApp());
      await tester.pump();

      final passwordFinder = find.widgetWithText(TextField, 'Password');
      expect(tester.widget<TextField>(passwordFinder).obscureText, isTrue);

      final eyeIcon = find.byIcon(Icons.visibility_off_outlined);
      await tester.ensureVisible(eyeIcon);
      await tester.tap(eyeIcon);
      await tester.pump();

      expect(tester.widget<TextField>(passwordFinder).obscureText, isFalse);
    });

    testWidgets('Empty-field validation shows errors', (
      WidgetTester tester,
    ) async {
      setScreen(tester, 800, 1000);
      await tester.pumpWidget(buildApp());
      await tester.pump();

      final loginBtn = find.byType(ElevatedButton);
      await tester.ensureVisible(loginBtn);
      await tester.tap(loginBtn);
      await tester.pump();

      expect(find.text('Please enter your email or username'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('Loading state is triggered on valid input', (
      WidgetTester tester,
    ) async {
      setScreen(tester, 800, 1000);
      await tester.pumpWidget(buildApp());
      await tester.pump();

      final emailField = find.widgetWithText(TextField, 'Email or username');
      final passwordField = find.widgetWithText(TextField, 'Password');
      await tester.ensureVisible(emailField);
      await tester.enterText(emailField, 'admin@nykitchen.com');
      await tester.enterText(passwordField, 'admin123');

      final loginBtn = find.byType(ElevatedButton);
      await tester.ensureVisible(loginBtn);
      await tester.tap(loginBtn);
      await tester.pump(); // trigger setState → loading = true

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Drain the pending 800ms timer to avoid "timer still pending" assertion
      await tester.pump(const Duration(milliseconds: 900));
    });
  });

  group('Short-height scrolling', () {
    testWidgets('Form is scrollable on short viewport', (
      WidgetTester tester,
    ) async {
      setScreen(tester, 360, 500);
      await tester.pumpWidget(buildApp());
      await tester.pump();

      expect(find.byType(SingleChildScrollView), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('200% text scale', () {
    testWidgets('No exceptions at 200% text scale', (
      WidgetTester tester,
    ) async {
      setScreen(tester, 800, 1000);
      tester.view.platformDispatcher.textScaleFactorTestValue = 2.0;
      await tester.pumpWidget(buildApp());
      await tester.pump();

      expect(tester.takeException(), isNull);

      tester.view.platformDispatcher.clearTextScaleFactorTestValue();
    });
  });

  group('Nav Rail Expansion and Platform Tests', () {
    testWidgets('CashierNavRail on Windows Desktop allows toggling expansion', (
      WidgetTester tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      int selectedIndex = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Row(
              children: [
                CashierNavRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (val) {
                    selectedIndex = val;
                  },
                ),
              ],
            ),
          ),
        ),
      );

      // Verify the menu button is present and layout starts collapsed (76px)
      final toggleFinder = find.byIcon(Symbols.menu);
      expect(toggleFinder, findsOneWidget);
      expect(tester.getSize(find.byType(CashierNavRail)).width, 76.0);

      // Tap to expand
      await tester.tap(toggleFinder);
      await tester.pumpAndSettle();

      // Verify menu_open is present and layout is expanded (240px)
      expect(find.byIcon(Symbols.menu_open), findsOneWidget);
      expect(tester.getSize(find.byType(CashierNavRail)).width, 240.0);

      // Verify text label is visible
      expect(find.text('Orders'), findsOneWidget);

      // Tap menu_open to collapse
      await tester.tap(find.byIcon(Symbols.menu_open));
      await tester.pumpAndSettle();

      // Verify collapsed state again
      expect(find.byIcon(Symbols.menu), findsOneWidget);
      expect(tester.getSize(find.byType(CashierNavRail)).width, 76.0);

      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('CashierNavRail on Android has no toggle and is fixed width (76px)', (
      WidgetTester tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Row(
              children: [
                CashierNavRail(
                  selectedIndex: 0,
                  onDestinationSelected: (_) {},
                ),
              ],
            ),
          ),
        ),
      );

      // Verify toggle button is not present
      expect(find.byIcon(Symbols.menu), findsNothing);
      expect(find.byIcon(Symbols.menu_open), findsNothing);

      // Verify width remains exactly 76px
      expect(tester.getSize(find.byType(CashierNavRail)).width, 76.0);

      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('AdminNavRail on Windows Desktop allows toggling expansion', (
      WidgetTester tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      int selectedIndex = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Row(
              children: [
                AdminNavRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (val) {
                    selectedIndex = val;
                  },
                ),
              ],
            ),
          ),
        ),
      );

      // Verify the menu button is present and layout starts collapsed (76px)
      final toggleFinder = find.byIcon(Symbols.menu);
      expect(toggleFinder, findsOneWidget);
      expect(tester.getSize(find.byType(AdminNavRail)).width, 76.0);

      // Tap to expand
      await tester.tap(toggleFinder);
      await tester.pumpAndSettle();

      // Verify menu_open is present and layout is expanded (240px)
      expect(find.byIcon(Symbols.menu_open), findsOneWidget);
      expect(tester.getSize(find.byType(AdminNavRail)).width, 240.0);

      // Verify text label is visible
      expect(find.text('Sales'), findsOneWidget);

      // Tap menu_open to collapse
      await tester.tap(find.byIcon(Symbols.menu_open));
      await tester.pumpAndSettle();

      // Verify collapsed state again
      expect(find.byIcon(Symbols.menu), findsOneWidget);
      expect(tester.getSize(find.byType(AdminNavRail)).width, 76.0);

      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('AdminNavRail on Android has no toggle and is fixed width (76px)', (
      WidgetTester tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Row(
              children: [
                AdminNavRail(
                  selectedIndex: 0,
                  onDestinationSelected: (_) {},
                ),
              ],
            ),
          ),
        ),
      );

      // Verify toggle button is not present
      expect(find.byIcon(Symbols.menu), findsNothing);
      expect(find.byIcon(Symbols.menu_open), findsNothing);

      // Verify width remains exactly 76px
      expect(tester.getSize(find.byType(AdminNavRail)).width, 76.0);

      debugDefaultTargetPlatformOverride = null;
    });
  });
}
