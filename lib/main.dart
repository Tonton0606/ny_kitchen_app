import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'core/session/session_manager.dart';
import 'features/auth/presentation/pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    headers: {
      'x-device-secret': dotenv.env['SUPABASE_DEVICE_SECRET'] ?? '',
    },
  );

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const NYKitchenApp());
}

class NYKitchenApp extends StatelessWidget {
  const NYKitchenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => SessionManager().updateActivity(),
      onPointerMove: (_) => SessionManager().updateActivity(),
      child: MaterialApp(
        title: 'N.Y Kitchen POS',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const LoginPage(),
      ),
    );
  }
}
