import 'dart:async';
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
import 'package:flutter/foundation.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set up global error boundary
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };
  
  PlatformDispatcher.instance.onError = (error, stack) {
    print('Async Error Caught: $error');
    return true; // Prevent app crash
  };
  
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Something went wrong', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(details.exceptionAsString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Restart app logic or just return to home
                if (navigatorKey.currentState != null) {
                  navigatorKey.currentState!.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
                  );
                }
              },
              child: const Text('Restart App'),
            ),
          ],
        ),
      ),
    );
  };
  if (Platform.isAndroid || Platform.isIOS) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }
  
  // Load environment variables
  Map<String, String> envVars = {};
  try {
    await dotenv.load(fileName: ".env");
    envVars = dotenv.env;
  } catch (e) {
    print('Failed to load .env from assets: $e');
    try {
      final file = File('.env');
      if (await file.exists()) {
        final lines = await file.readAsLines();
        for (var line in lines) {
          if (line.trim().isEmpty || line.startsWith('#')) continue;
          final idx = line.indexOf('=');
          if (idx != -1) {
            final key = line.substring(0, idx).trim();
            final value = line.substring(idx + 1).trim();
            envVars[key] = value;
          }
        }
      }
    } catch (_) {}
  }

  // Initialize Supabase if credentials exist
  if (envVars.containsKey('SUPABASE_URL') && envVars.containsKey('SUPABASE_ANON_KEY')) {
    await Supabase.initialize(
      url: envVars['SUPABASE_URL']!,
      anonKey: envVars['SUPABASE_ANON_KEY']!,
      headers: {
        'x-device-secret': envVars['SUPABASE_DEVICE_SECRET'] ?? '',
      },
    );

    // Initial fetch and periodic auto-sync from cloud
    final syncService = SyncService();
    syncService.startAutomaticSync(intervalSeconds: 10);
    print("Started automatic cloud synchronization (every 10 seconds)");
  } else {
    print("WARNING: Supabase credentials not found. Cloud sync is disabled.");
  }

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

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NYKitchenApp extends StatefulWidget {
  const NYKitchenApp({super.key});

  @override
  State<NYKitchenApp> createState() => _NYKitchenAppState();
}

class _NYKitchenAppState extends State<NYKitchenApp> {
  Timer? _sessionTimer;

  @override
  void initState() {
    super.initState();
    // Check for session expiration every 1 minute
    _sessionTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (SessionManager().currentUser != null && SessionManager().isSessionExpired()) {
        SessionManager().clearSession(reason: 'Session expired due to inactivity');
        if (navigatorKey.currentState != null) {

          navigatorKey.currentState!.pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
          if (navigatorKey.currentContext != null) {
            ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
              const SnackBar(
                content: Text('Session expired due to inactivity. Please log in again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => SessionManager().updateActivity(),
      onPointerMove: (_) => SessionManager().updateActivity(),
      onPointerUp: (_) => SessionManager().updateActivity(),
      onPointerHover: (_) => SessionManager().updateActivity(),
      onPointerCancel: (_) => SessionManager().updateActivity(),
      child: MaterialApp(
        navigatorKey: navigatorKey,
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
