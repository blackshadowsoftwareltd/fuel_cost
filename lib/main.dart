import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/home_screen.dart';
import 'services/fuel_storage_service.dart';
import 'services/theme_service.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Auto-import CSV data only if DB is empty
  final existingEntries = await FuelStorageService.getFuelEntries();
  if (existingEntries.isEmpty) {
    try {
      final csvContent = await rootBundle.loadString('assets/fuel_entries_fixed.csv');
      final count = await FuelStorageService.importFromCsv(csvContent);
      debugPrint('Auto-imported $count fuel entries from CSV');
    } catch (e) {
      debugPrint('CSV auto-import skipped: $e');
    }
  }

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
