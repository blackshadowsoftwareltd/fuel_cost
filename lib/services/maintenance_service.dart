import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/maintenance_entry.dart';

class MaintenanceService {
  static const String _maintenanceKey = 'maintenance_entries';
  static const _uuid = Uuid();

  static Future<List<MaintenanceEntry>> getMaintenanceEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_maintenanceKey);
    if (json == null || json.isEmpty) return [];
    final entries = MaintenanceEntry.listFromJson(json);
    entries.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return entries;
  }

  static Future<void> saveMaintenanceEntry(MaintenanceEntry entry) async {
    final entries = await getMaintenanceEntries();
    final index = entries.indexWhere((e) => e.id == entry.id);
    if (index >= 0) {
      entries[index] = entry;
    } else {
      entries.add(entry);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_maintenanceKey, MaintenanceEntry.listToJson(entries));
  }

  static Future<void> deleteMaintenanceEntry(String id) async {
    final entries = await getMaintenanceEntries();
    entries.removeWhere((e) => e.id == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_maintenanceKey, MaintenanceEntry.listToJson(entries));
  }

  static Future<List<MaintenanceEntry>> getEntriesForVehicle(
      String vehicleId) async {
    final entries = await getMaintenanceEntries();
    return entries.where((e) => e.vehicleId == vehicleId).toList();
  }

  static double getTotalMaintenanceCost(List<MaintenanceEntry> entries) {
    return entries.fold(0.0, (sum, e) => sum + e.cost);
  }

  static String generateId() => _uuid.v4();
}
