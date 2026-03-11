import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/vehicle.dart';

class VehicleService {
  static const String _vehiclesKey = 'vehicles';
  static const String _selectedVehicleKey = 'selected_vehicle_id';
  static const String _entryVehicleMapKey = 'entry_vehicle_map';
  static const _uuid = Uuid();

  // --- Vehicle CRUD ---

  static Future<List<Vehicle>> getVehicles() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_vehiclesKey);
    if (json == null || json.isEmpty) return [];
    return Vehicle.listFromJson(json);
  }

  static Future<void> saveVehicle(Vehicle vehicle) async {
    final vehicles = await getVehicles();
    final index = vehicles.indexWhere((v) => v.id == vehicle.id);
    if (index >= 0) {
      vehicles[index] = vehicle;
    } else {
      vehicles.add(vehicle);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_vehiclesKey, Vehicle.listToJson(vehicles));
  }

  static Future<void> deleteVehicle(String id) async {
    final vehicles = await getVehicles();
    vehicles.removeWhere((v) => v.id == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_vehiclesKey, Vehicle.listToJson(vehicles));

    final selected = await getSelectedVehicleId();
    if (selected == id) {
      await setSelectedVehicleId(null);
    }
  }

  // --- Selected Vehicle ---

  static Future<String?> getSelectedVehicleId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedVehicleKey);
  }

  static Future<void> setSelectedVehicleId(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(_selectedVehicleKey);
    } else {
      await prefs.setString(_selectedVehicleKey, id);
    }
  }

  static Future<Vehicle?> getSelectedVehicle() async {
    final id = await getSelectedVehicleId();
    if (id == null) return null;
    final vehicles = await getVehicles();
    try {
      return vehicles.firstWhere((v) => v.id == id);
    } catch (_) {
      return null;
    }
  }

  // --- Entry-Vehicle Mapping ---

  static Future<Map<String, String>> _getEntryVehicleMap() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_entryVehicleMapKey);
    if (json == null || json.isEmpty) return {};
    return Map<String, String>.from(jsonDecode(json));
  }

  static Future<void> assignVehicleToEntry(String entryId, String vehicleId) async {
    final map = await _getEntryVehicleMap();
    map[entryId] = vehicleId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_entryVehicleMapKey, jsonEncode(map));
  }

  static Future<String?> getVehicleIdForEntry(String entryId) async {
    final map = await _getEntryVehicleMap();
    return map[entryId];
  }

  static Future<Set<String>> getEntryIdsForVehicle(String vehicleId) async {
    final map = await _getEntryVehicleMap();
    return map.entries
        .where((e) => e.value == vehicleId)
        .map((e) => e.key)
        .toSet();
  }

  static Future<void> removeEntryMapping(String entryId) async {
    final map = await _getEntryVehicleMap();
    map.remove(entryId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_entryVehicleMapKey, jsonEncode(map));
  }

  static String generateId() => _uuid.v4();
}
