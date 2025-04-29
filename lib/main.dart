import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/home_screen.dart';
import 'providers/settings_provider.dart';
import 'services/app_initialization.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await AppInitializationService.initialize();
    runApp(
      const ProviderScope(
        child: HelvarNetApp(),
      ),
    );
  } catch (e) {
    await AppInitializationService.handleInitializationFailure(e);
    runApp(
      const ProviderScope(
        child: HelvarNetApp(),
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
