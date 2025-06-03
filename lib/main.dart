import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grms_designer/models/helvar_models/workgroup.dart';
import 'package:grms_designer/providers/centralized_polling_provider.dart';
import 'package:grms_designer/providers/workgroups_provider.dart';
import 'screens/home_screen.dart';

import 'providers/settings_provider.dart';
import 'services/app_initialization.dart';
import 'services/log_service.dart';
import 'utils/core/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();

  final logService = container.read(logServiceProvider.notifier);
  initLogger(logService);

  logInfo('Application starting', tag: 'App');

  try {
    await AppInitializationService.initialize();
    logInfo('Application initialized successfully', tag: 'App');

    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const HelvarNetApp(),
      ),
    );
  } catch (e, stackTrace) {
    logError('Initialization error: $e', tag: 'App', stackTrace: stackTrace);
    await AppInitializationService.handleInitializationFailure(e);

    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const HelvarNetApp(),
      ),
    );
  }
}

class HelvarNetApp extends ConsumerStatefulWidget {
  const HelvarNetApp({super.key});

  @override
  HelvarNetAppState createState() => HelvarNetAppState();
}

class HelvarNetAppState extends ConsumerState<HelvarNetApp> {
  bool _pollingListenerInitialized = false;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    if (!_pollingListenerInitialized) {
      ref.listen<List<Workgroup>>(workgroupsProvider, (previous, next) {
        if ((previous == null || previous.isEmpty) && next.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final pollingManager = ref.read(pollingManagerProvider.notifier);
            for (final workgroup in next) {
              if (workgroup.pollEnabled) {
                pollingManager.startWorkgroupPolling(workgroup.id);
              }
            }
          });
        }
      });
      _pollingListenerInitialized = true;
    }

    return MaterialApp(
      title: 'HelvarNet Manager',
      themeMode: themeMode,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        brightness: Brightness.dark,
      ),
      home: const HomeScreen(),
    );
  }
}
