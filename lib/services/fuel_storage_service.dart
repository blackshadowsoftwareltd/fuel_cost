import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import '../models/fuel_entry.dart';
import 'database_service.dart';
import 'sync_service.dart';

class FuelStorageService {
  static Future<List<FuelEntry>> getFuelEntries() async {
    final isar = await DatabaseService.database;
    return await isar.fuelEntrys.where().sortByDateTime().findAll();
  }

  static Future<void> saveFuelEntry(FuelEntry entry) async {
    final isar = await DatabaseService.database;
    await isar.writeTxn(() async {
      await isar.fuelEntrys.put(entry);
    });

    if (entry.odometerReading != null) {
      await setCurrentOdometer(entry.odometerReading!);
    }
  }

  static Future<void> deleteFuelEntry(String id) async {
    final isar = await DatabaseService.database;
    await isar.writeTxn(() async {
      await isar.fuelEntrys.deleteById(id);
    });
  }

  static Future<double> getTotalFuelCost() async {
    final isar = await DatabaseService.database;
    final sum = await isar.fuelEntrys.where().totalCostProperty().sum();
    return sum;
  }

  static Future<double> getTotalLiters() async {
    final isar = await DatabaseService.database;
    final sum = await isar.fuelEntrys.where().litersProperty().sum();
    return sum;
  }

  static Future<double> getAveragePricePerLiter() async {
    final totalCost = await getTotalFuelCost();
    final totalLiters = await getTotalLiters();
    return totalLiters > 0 ? totalCost / totalLiters : 0.0;
  }

  static Future<double?> getAverageMileage() async {
    final entries = await getFuelEntries();
    if (entries.length < 2) return null;

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
    return FuelEntry.calculateMileage(entries.last, entries[entries.length - 2]);
  }

  static Future<double?> getCurrentOdometer() async {
    final isar = await DatabaseService.database;
    final lastEntry = await isar.fuelEntrys
        .filter()
        .odometerReadingIsNotNull()
        .sortByDateTimeDesc()
        .findFirst();
    return lastEntry?.odometerReading;
  }

  static Future<void> setCurrentOdometer(double odometer) async {
    // Odometer is now tracked via entries, no separate storage needed
  }

  static Future<double?> calculateCurrentMileage(double liters, double? currentOdometer) async {
    if (currentOdometer == null) return null;

    final isar = await DatabaseService.database;
    final lastEntry = await isar.fuelEntrys
        .filter()
        .odometerReadingIsNotNull()
        .sortByDateTimeDesc()
        .findFirst();

    if (lastEntry == null || lastEntry.odometerReading == null) return null;

    final distance = currentOdometer - lastEntry.odometerReading!;
    if (distance > 0) {
      return distance / liters;
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getMileageCalculationDetails(double liters, double? currentOdometer) async {
    if (currentOdometer == null) return null;

    final isar = await DatabaseService.database;
    final lastEntry = await isar.fuelEntrys
        .filter()
        .odometerReadingIsNotNull()
        .sortByDateTimeDesc()
        .findFirst();

    if (lastEntry == null || lastEntry.odometerReading == null) return null;

    final distance = currentOdometer - lastEntry.odometerReading!;
    if (distance > 0) {
      final mileage = distance / liters;
      return {
        'currentOdometer': currentOdometer,
        'lastOdometer': lastEntry.odometerReading!,
        'distance': distance,
        'liters': liters,
        'mileage': mileage,
        'lastFuelDate': lastEntry.dateTime,
      };
    }
    return null;
  }

  static Future<void> updateFuelEntry(FuelEntry entry) async {
    final isar = await DatabaseService.database;
    await isar.writeTxn(() async {
      await isar.fuelEntrys.put(entry);
    });
  }

  static Future<String> exportToCsv() async {
    final entries = await getFuelEntries();
    final buffer = StringBuffer();
    buffer.writeln('id,liters,pricePerLiter,totalCost,dateTime,odometerReading');
    for (final entry in entries) {
      buffer.writeln(
        '${entry.id},${entry.liters},${entry.pricePerLiter},${entry.totalCost},${entry.dateTime.toIso8601String()},${entry.odometerReading ?? ''}',
      );
    }
    return buffer.toString();
  }

  static Future<int> importFromCsv(String csvContent) async {
    final lines = csvContent.trim().split('\n');
    if (lines.length < 2) return 0;

    // Skip header
    int imported = 0;
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final parts = line.split(',');
      if (parts.length < 5) continue;

      try {
        final entry = FuelEntry()
          ..id = parts[0]
          ..liters = double.parse(parts[1])
          ..pricePerLiter = double.parse(parts[2])
          ..totalCost = double.parse(parts[3])
          ..dateTime = DateTime.parse(parts[4])
          ..odometerReading = parts.length > 5 && parts[5].isNotEmpty ? double.parse(parts[5]) : null;

        await saveFuelEntry(entry);
        imported++;
      } catch (e) {
        debugPrint('Skipping invalid CSV row $i: $e');
      }
    }
    return imported;
  }

  static Future<void> clearAllData() async {
    final isar = await DatabaseService.database;
    await isar.writeTxn(() async {
      await isar.fuelEntrys.clear();
    });
    await SyncService.clearAllSyncTimes();
  }

  static Future<void> clearFuelEntries() async {
    final isar = await DatabaseService.database;
    await isar.writeTxn(() async {
      await isar.fuelEntrys.clear();
    });
    await SyncService.clearAllSyncTimes();
  }

  static Future<void> clearCurrentOdometer() async {
    // Odometer is tracked via entries - clearing it means nothing separate
  }

  static Future<void> clearAllSharedPreferences() async {
    final isar = await DatabaseService.database;
    await isar.writeTxn(() async {
      await isar.clear();
    });
  }
}
