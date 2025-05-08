import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/home_screen.dart';
import 'providers/settings_provider.dart';
import 'services/app_initialization.dart';
import 'services/log_service.dart';
import 'utils/logger.dart';

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

class HelvarNetApp extends ConsumerWidget {
  const HelvarNetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

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
