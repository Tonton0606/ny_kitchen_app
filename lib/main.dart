import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:window_manager/window_manager.dart';
import 'core/theme/app_theme.dart';
import 'core/session/session_manager.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/shared/widgets/custom_title_bar.dart';
import 'core/services/sync_service.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (Platform.isAndroid || Platform.isIOS) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }
  
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

  // Initial fetch and periodic auto-sync from cloud
  final syncService = SyncService();
  syncService.startAutomaticSync(intervalSeconds: 10);
  print("Started automatic cloud synchronization (every 10 seconds)");

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 720),
      minimumSize: Size(1024, 768),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.maximize();
      await windowManager.focus();
    });
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
        builder: (context, child) {
          return Material(
            child: Column(
              children: [
                const CustomTitleBar(),
                Expanded(child: child ?? const SizedBox.shrink()),
              ],
            ),
          );
        },
        home: const LoginPage(),
      ),
    );
  }
}
