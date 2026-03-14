import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/home_screen.dart';
import 'services/theme_service.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ProviderScope(child: FuelCostApp()));
}

class FuelCostApp extends ConsumerWidget {
  const FuelCostApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Fuel Cost',
      debugShowCheckedModeBanner: false,
      theme: ThemeService.buildLightTheme(themeState.accentColor),
      darkTheme: ThemeService.buildDarkTheme(themeState.accentColor),
      themeMode: themeState.themeMode,
      home: const HomeScreen(),
    );
  }
}
