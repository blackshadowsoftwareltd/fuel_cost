import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fuel_entry.dart';
import 'sync_service.dart';

class FuelStorageService {
  static const String _fuelEntriesKey = 'fuel_entries';
  static const String _currentOdometerKey = 'current_odometer';

  static Future<List<FuelEntry>> getFuelEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_fuelEntriesKey);
    
    if (jsonString == null) {
      return [];
    }

    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList.map((json) => FuelEntry.fromJson(json)).toList();
  }

  static Future<void> saveFuelEntry(FuelEntry entry) async {
    final entries = await getFuelEntries();
    entries.add(entry);
    await _saveEntries(entries);
    
    // Update current odometer if provided
    if (entry.odometerReading != null) {
      await setCurrentOdometer(entry.odometerReading!);
    }
  }

  static Future<void> deleteFuelEntry(String id) async {
    final entries = await getFuelEntries();
    entries.removeWhere((entry) => entry.id == id);
    await _saveEntries(entries);
  }

  static Future<void> _saveEntries(List<FuelEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(entries.map((e) => e.toJson()).toList());
    await prefs.setString(_fuelEntriesKey, jsonString);
  }

  static Future<double> getTotalFuelCost() async {
    final entries = await getFuelEntries();
    double total = 0.0;
    for (final entry in entries) {
      total += entry.totalCost;
    }
    return total;
  }

  static Future<double> getTotalLiters() async {
    final entries = await getFuelEntries();
    double total = 0.0;
    for (final entry in entries) {
      total += entry.liters;
    }
    return total;
  }

  static Future<double> getAveragePricePerLiter() async {
    final entries = await getFuelEntries();
    if (entries.isEmpty) return 0.0;
    
    double totalCost = 0.0;
    double totalLiters = 0.0;
    for (final entry in entries) {
      totalCost += entry.totalCost;
      totalLiters += entry.liters;
    }
    
    return totalLiters > 0 ? totalCost / totalLiters : 0.0;
  }

  static Future<double?> getAverageMileage() async {
    final entries = await getFuelEntries();
    if (entries.length < 2) return null;
    
    // Sort entries by date
    entries.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    
    List<double> mileages = [];
    for (int i = 1; i < entries.length; i++) {
      final mileage = FuelEntry.calculateMileage(entries[i], entries[i - 1]);
      if (mileage != null) {
        mileages.add(mileage);
      }
    }
    
    if (mileages.isEmpty) return null;
    
    return mileages.reduce((a, b) => a + b) / mileages.length;
  }

  static Future<double?> getLastMileage() async {
    final entries = await getFuelEntries();
    if (entries.length < 2) return null;
    
    // Sort entries by date
    entries.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    
    // Get the last two entries
    return FuelEntry.calculateMileage(entries.last, entries[entries.length - 2]);
  }

  static Future<double?> getCurrentOdometer() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_currentOdometerKey);
  }

  static Future<void> setCurrentOdometer(double odometer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_currentOdometerKey, odometer);
  }

  static Future<double?> calculateCurrentMileage(double liters, double? currentOdometer) async {
    if (currentOdometer == null) return null;
    
    final entries = await getFuelEntries();
    if (entries.isEmpty) return null;
    
    // Sort entries by date and get the most recent entry with odometer reading
    entries.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    
    for (final entry in entries) {
      if (entry.odometerReading != null) {
        final distance = currentOdometer - entry.odometerReading!;
        if (distance > 0) {
          return distance / liters;
        }
        break;
      }
    }
    
    return null;
  }

  static Future<Map<String, dynamic>?> getMileageCalculationDetails(double liters, double? currentOdometer) async {
    if (currentOdometer == null) return null;
    
    final entries = await getFuelEntries();
    if (entries.isEmpty) return null;
    
    // Sort entries by date and get the most recent entry with odometer reading
    entries.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    
    for (final entry in entries) {
      if (entry.odometerReading != null) {
        final distance = currentOdometer - entry.odometerReading!;
        if (distance > 0) {
          final mileage = distance / liters;
          return {
            'currentOdometer': currentOdometer,
            'lastOdometer': entry.odometerReading!,
            'distance': distance,
            'liters': liters,
            'mileage': mileage,
            'lastFuelDate': entry.dateTime,
          };
        }
        break;
      }
    }
    
    return null;
  }

  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_fuelEntriesKey);
    await prefs.remove(_currentOdometerKey);
    // Also clear sync times when clearing all fuel data
    await SyncService.clearAllSyncTimes();
  }

  static Future<void> clearFuelEntries() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_fuelEntriesKey);
    // Also clear sync times when clearing fuel entries
    await SyncService.clearAllSyncTimes();
  }

  static Future<void> clearCurrentOdometer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentOdometerKey);
  }

  static Future<void> clearAllSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}