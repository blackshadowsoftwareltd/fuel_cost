import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vehicle.dart';
import '../services/vehicle_service.dart';
import '../models/fuel_entry.dart';
import 'fuel_entries_provider.dart';

final vehiclesProvider = FutureProvider<List<Vehicle>>((ref) async {
  return await VehicleService.getVehicles();
});

final selectedVehicleIdProvider = StateProvider<String?>((ref) => null);

final selectedVehicleProvider = FutureProvider<Vehicle?>((ref) async {
  final selectedId = ref.watch(selectedVehicleIdProvider);
  if (selectedId == null) return null;
  final vehicles = await ref.watch(vehiclesProvider.future);
  try {
    return vehicles.firstWhere((v) => v.id == selectedId);
  } catch (_) {
    return null;
  }
});

/// Entries filtered by selected vehicle
final vehicleFilteredEntriesProvider = FutureProvider<List<FuelEntry>>((ref) async {
  final allEntries = await ref.watch(fuelEntriesProvider.future);
  final selectedId = ref.watch(selectedVehicleIdProvider);

  if (selectedId == null) return allEntries;

  final entryIds = await VehicleService.getEntryIdsForVehicle(selectedId);
  if (entryIds.isEmpty) return [];
  return allEntries.where((e) => entryIds.contains(e.id)).toList();
});
