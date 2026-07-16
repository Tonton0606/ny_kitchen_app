import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/login_page.dart';

void main() {
  runApp(const NYKitchenApp());
}

class NYKitchenApp extends StatefulWidget {
  const NYKitchenApp({super.key});

  @override
  State<NYKitchenApp> createState() => _NYKitchenAppState();
}

class _NYKitchenAppState extends State<NYKitchenApp> {
  final ThemeMode _themeMode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'N.Y Kitchen POS',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      debugShowCheckedModeBanner: false,
      home: const LoginPage(),
    );
  }
}
