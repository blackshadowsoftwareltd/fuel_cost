import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/fuel_storage_service.dart';
import '../services/currency_service.dart';
import '../business_logic/fuel_calculations.dart';
import 'fuel_entries_provider.dart';

part 'summary_providers.g.dart';

@riverpod
Future<double> totalCost(Ref ref) async {
  // Watch fuel entries to trigger recalculation when entries change
  await ref.watch(fuelEntriesProvider.future);
  return await FuelStorageService.getTotalFuelCost();
}

@riverpod
Future<double> totalLiters(Ref ref) async {
  // Watch fuel entries to trigger recalculation when entries change
  await ref.watch(fuelEntriesProvider.future);
  return await FuelStorageService.getTotalLiters();
}

@riverpod
Future<double?> averageMileage(Ref ref) async {
  // Watch fuel entries to trigger recalculation when entries change
  await ref.watch(fuelEntriesProvider.future);
  return await FuelStorageService.getAverageMileage();
}

@riverpod
Future<double?> currentOdometer(Ref ref) async {
  // Watch fuel entries to trigger recalculation when entries change
  await ref.watch(fuelEntriesProvider.future);
  return await FuelStorageService.getCurrentOdometer();
}

@riverpod
Future<Map<String, double>> mileageCalculations(Ref ref) async {
  final entries = await ref.watch(fuelEntriesProvider.future);
  final totalLiters = await ref.watch(totalLitersProvider.future);
  
  return FuelCalculations.calculateMileageMetrics(entries, totalLiters);
}

@riverpod
Future<String> currency(Ref ref) async {
  return await CurrencyService.getSelectedCurrency();
}

@riverpod
class CurrencyNotifier extends _$CurrencyNotifier {
  @override
  Future<String> build() async {
    return await CurrencyService.getSelectedCurrency();
  }

  Future<void> setCurrency(String currency) async {
    state = const AsyncValue.loading();
    try {
      await CurrencyService.setSelectedCurrency(currency);
      state = AsyncValue.data(currency);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}