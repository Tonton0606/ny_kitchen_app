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
import 'core/services/backend_sync_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set up global error boundary
  FlutterError.onError = (FlutterErrorDetails details) {
    final exceptionStr = details.exception.toString();
    // Filter known Flutter Windows framework assertion on Alt / Alt-Tab modifier keydown events
    if (exceptionStr.contains('raw_keyboard.dart') ||
        (exceptionStr.contains('keysPressed') && exceptionStr.contains('RawKeyDownEvent'))) {
      return;
    }
    FlutterError.presentError(details);
  };
  
  PlatformDispatcher.instance.onError = (error, stack) {
    final errorStr = error.toString();
    if (errorStr.contains('raw_keyboard.dart') ||
        (errorStr.contains('keysPressed') && errorStr.contains('RawKeyDownEvent'))) {
      return true; // Harmless framework assertion on Windows Alt-key; ignore
    }
    if (kDebugMode) {
      debugPrint('Async Error Caught: $error');
    }
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
            const Text(
              'An unexpected error occurred. Please restart the application.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
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
  // Read recognized keys only; never print configuration values.
  const configKeys = [
    'SUPABASE_URL',
    'SUPABASE_ANON_KEY',
    'SUPABASE_DEVICE_SECRET',
    'SYNC_BACKEND',
    'BACKEND_URL',
    'BACKEND_DEVICE_TOKEN',
    'AI_SERVICE_KEY',
  ];
  final processEnvVars = <String, String>{};
  for (final key in configKeys) {
    final value = Platform.environment[key]?.trim();
    if (value != null && value.isNotEmpty) processEnvVars[key] = value;
  }
  final envVars = <String, String>{};

  final executableDirectory = File(Platform.resolvedExecutable).parent.path;
  final envFiles = <File>[
    File('.env'),
    File('$executableDirectory${Platform.pathSeparator}.env'),
  ];
  var loadedEnvFile = false;
  for (final file in envFiles) {
    try {
      if (!await file.exists()) continue;
      for (var line in await file.readAsLines()) {
        final trimmedLine = line.trim();
        if (trimmedLine.isEmpty || trimmedLine.startsWith('#')) continue;
        final idx = line.indexOf('=');
        if (idx < 0) continue;
        final key = line.substring(0, idx).trim();
        if (!configKeys.contains(key)) continue;
        var value = line.substring(idx + 1).trim();
        if (value.length >= 2 &&
            ((value.startsWith('"') && value.endsWith('"')) ||
                (value.startsWith("'") && value.endsWith("'")))) {
          value = value.substring(1, value.length - 1);
        }
        envVars[key] = value;
      }
      loadedEnvFile = true;
    } catch (_) {}
  }
  if (!loadedEnvFile) {
    try {
      await dotenv.load(fileName: '.env');
      for (final key in configKeys) {
        final value = dotenv.maybeGet(key);
        if (value != null && value.trim().isNotEmpty) {
          envVars.putIfAbsent(key, () => value.trim());
        }
      }
    } catch (_) {
      if (kDebugMode) {
        debugPrint('No cloud configuration found; continuing with local storage.');
      }
    }
  }
  envVars.addAll(processEnvVars);
  if (!dotenv.isInitialized && envVars.isNotEmpty) {
    try {
      dotenv.loadFromString(
        envString: envVars.entries.map((e) => '${e.key}=${e.value}').join('\n'),
      );
    } catch (_) {}
  }

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 720),
      minimumSize: Size(1024, 720),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.maximize();
      await windowManager.show();
      await windowManager.focus();
    });
  }
  // Local platform/database setup precedes all optional network work.
  SyncService.backendMode = envVars['SYNC_BACKEND'] == 'ubuntu';
  if (SyncService.backendMode) {
    try {
      final uri = Uri.parse(envVars['BACKEND_URL'] ?? '');
      const storage = FlutterSecureStorage();
      final storageKey = 'nyk_backend_token:$uri';
      final supplied = envVars['BACKEND_DEVICE_TOKEN'];
      final token = supplied?.isNotEmpty == true
          ? supplied!
          : await storage.read(key: storageKey) ?? '';
      final service = BackendSyncService(baseUrl: uri, token: token);
      if (supplied?.isNotEmpty == true) {
        await storage.write(key: storageKey, value: token);
      }
      BackendSyncService.instance = service;
    } catch (_) {
      SyncService.syncStatusNotifier.value = 'Backend configuration unavailable';
      if (kDebugMode) {
        debugPrint('Backend configuration unavailable; local operation remains available.');
      }
    }
  } else if (envVars['SUPABASE_URL']?.isNotEmpty == true &&
      envVars['SUPABASE_ANON_KEY']?.isNotEmpty == true) {
    try {
      await Supabase.initialize(
        url: envVars['SUPABASE_URL']!,
        anonKey: envVars['SUPABASE_ANON_KEY']!,
        headers: {'x-device-secret': envVars['SUPABASE_DEVICE_SECRET'] ?? ''},
      );
    } catch (_) {
      SyncService.syncStatusNotifier.value = 'Cloud initialization failed';
      if (kDebugMode) {
        debugPrint('Cloud initialization unavailable; continuing with local storage.');
      }
    }
  } else {
    SyncService.syncStatusNotifier.value = 'Cloud credentials unavailable';
  }

  // Load configured sync mode preference (Manual vs Automatic)
  await SyncService().initSyncMode();

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
          return Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (context) => Material(
                  child: Column(
                    children: [
                      const CustomTitleBar(),
                      Expanded(child: child ?? const SizedBox.shrink()),
                      if (SyncService.backendMode)
                        SafeArea(top: false, child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: BackendSyncService.instance == null
                              ? const Text('Online sync not configured; working locally')
                              : ValueListenableBuilder<String>(
                                  valueListenable: BackendSyncService.instance!.status,
                                  builder: (context, value, child) => Text(value,
                                    style: Theme.of(context).textTheme.bodySmall),
                                ),
                        ))
                      else
                        ValueListenableBuilder<String>(
                          valueListenable: SyncService.syncModeNotifier,
                          builder: (context, mode, _) {
                            if (mode != 'automatic') return const SizedBox.shrink();
                            return SafeArea(
                              top: false,
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: ValueListenableBuilder<String>(
                                  valueListenable: SyncService.syncStatusNotifier,
                                  builder: (context, status, _) => Text(
                                    'Cloud sync: $status',
                                    style: Theme.of(context).textTheme.bodySmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        home: const LoginPage(),
      ),
    );
  }
}
