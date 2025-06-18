import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../models/fuel_entry.dart';
import './auth_service.dart';
import './fuel_storage_service.dart';

class SyncService {
  static const String _baseUrl = 'http://localhost:3002';

  static Future<void> syncWithServer() async {
    final userId = await AuthService.getUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get local fuel entries
      final localEntries = await FuelStorageService.getFuelEntries();

      if (localEntries.isEmpty) {
        log('No local entries to sync');
        return;
      }

      // Prepare bulk data for upload
      final bulkData = localEntries.map((entry) {
        final entryMap = <String, dynamic>{
          'liters': entry.liters,
          'price_per_liter': entry.pricePerLiter,
          'total_cost': entry.totalCost,
          'date_time': entry.dateTime.toUtc().toIso8601String(),
        };

        // Only include odometer_reading if it's not null
        if (entry.odometerReading != null) {
          entryMap['odometer_reading'] = entry.odometerReading;
        }

        return entryMap;
      }).toList();

      // Upload bulk data to server
      final headers = AuthService.getAuthHeaders();
      final requestBody = json.encode({'user_id': userId, 'entries': bulkData});

      // Debug: Print the request body
      print('Sync request body: $requestBody');

      final response = await http.post(
        Uri.parse('$_baseUrl/api/fuel-entries/bulk'),
        headers: headers,
        body: requestBody,
      );

      print('Sync response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Sync successful
        return;
      } else {
        String errorMessage = 'Sync failed';
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['message'] ?? errorData.toString();
        } catch (e) {
          errorMessage = response.body;
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('TimeoutException')) {
        throw Exception('Cannot connect to server. Please check your internet connection.');
      }
      rethrow;
    }
  }

  static Future<List<FuelEntry>> downloadFromServer() async {
    final userId = await AuthService.getUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final headers = AuthService.getAuthHeaders();
      final response = await http.get(Uri.parse('$_baseUrl/api/fuel-entries/$userId'), headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> entriesJson = json.decode(response.body);

        return entriesJson.map((entryJson) {
          return FuelEntry(
            id: entryJson['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
            liters: double.parse(entryJson['liters']?.toString() ?? '0'),
            pricePerLiter: double.parse(entryJson['price_per_liter']?.toString() ?? '0'),
            totalCost: double.parse(entryJson['total_cost']?.toString() ?? '0'),
            dateTime: DateTime.parse(entryJson['date_time']),
            odometerReading: entryJson['odometer_reading'] != null
                ? double.parse(entryJson['odometer_reading'].toString())
                : null,
          );
        }).toList();
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to download data');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('TimeoutException')) {
        throw Exception('Cannot connect to server. Please check your internet connection.');
      }
      rethrow;
    }
  }

  static Future<void> fullSync() async {
    final userId = await AuthService.getUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // First upload local data to server
      await syncWithServer();

      // Then download server data and merge with local data
      final serverEntries = await downloadFromServer();
      final localEntries = await FuelStorageService.getFuelEntries();

      // Create a map of local entries by their timestamp for quick lookup
      final localEntryMap = <String, FuelEntry>{};
      for (final entry in localEntries) {
        final key = '${entry.dateTime.millisecondsSinceEpoch}_${entry.liters}_${entry.totalCost}';
        localEntryMap[key] = entry;
      }

      // Add server entries that don't exist locally
      for (final serverEntry in serverEntries) {
        final key = '${serverEntry.dateTime.millisecondsSinceEpoch}_${serverEntry.liters}_${serverEntry.totalCost}';
        if (!localEntryMap.containsKey(key)) {
          await FuelStorageService.saveFuelEntry(serverEntry);
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> uploadEntry(FuelEntry entry) async {
    final userId = await AuthService.getUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final headers = AuthService.getAuthHeaders();
      final entryMap = <String, dynamic>{
        'user_id': userId,
        'liters': entry.liters,
        'price_per_liter': entry.pricePerLiter,
        'total_cost': entry.totalCost,
        'date_time': entry.dateTime.toUtc().toIso8601String(),
      };

      // Only include odometer_reading if it's not null
      if (entry.odometerReading != null) {
        entryMap['odometer_reading'] = entry.odometerReading;
      }

      final requestBody = json.encode(entryMap);

      // Debug: Print the request body
      print('Upload entry request body: $requestBody');

      final response = await http.post(Uri.parse('$_baseUrl/api/fuel-entries'), headers: headers, body: requestBody);

      print('Upload entry response: ${response.statusCode} - ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        String errorMessage = 'Failed to upload entry';
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['message'] ?? errorData.toString();
        } catch (e) {
          errorMessage = response.body;
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('TimeoutException')) {
        throw Exception('Cannot connect to server. Please check your internet connection.');
      }
      rethrow;
    }
  }

  static Future<void> deleteEntryFromServer(String entryId) async {
    final userId = await AuthService.getUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final headers = AuthService.getAuthHeaders();
      final response = await http.delete(Uri.parse('$_baseUrl/api/fuel-entries/$userId/$entryId'), headers: headers);

      if (response.statusCode != 200 && response.statusCode != 204) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to delete entry from server');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('TimeoutException')) {
        throw Exception('Cannot connect to server. Please check your internet connection.');
      }
      rethrow;
    }
  }

  static Future<void> bulkDeleteFromServer(List<String> entryIds) async {
    final userId = await AuthService.getUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final headers = AuthService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/api/fuel-entries/bulk/delete'),
        headers: headers,
        body: json.encode({'user_id': userId, 'entry_ids': entryIds}),
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to bulk delete entries from server');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('TimeoutException')) {
        throw Exception('Cannot connect to server. Please check your internet connection.');
      }
      rethrow;
    }
  }

  static Future<void> updateEntryOnServer(FuelEntry entry) async {
    final userId = await AuthService.getUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final headers = AuthService.getAuthHeaders();
      final response = await http.put(
        Uri.parse('$_baseUrl/api/fuel-entries/$userId/${entry.id}'),
        headers: headers,
        body: json.encode({
          'liters': entry.liters,
          'price_per_liter': entry.pricePerLiter,
          'total_cost': entry.totalCost,
          'date_time': entry.dateTime.toUtc().toIso8601String(),
          'odometer_reading': entry.odometerReading,
        }),
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update entry on server');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('TimeoutException')) {
        throw Exception('Cannot connect to server. Please check your internet connection.');
      }
      rethrow;
    }
  }

  static Future<FuelEntry?> getSpecificEntry(String entryId) async {
    final userId = await AuthService.getUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final headers = AuthService.getAuthHeaders();
      final response = await http.get(Uri.parse('$_baseUrl/api/fuel-entries/$userId/$entryId'), headers: headers);

      if (response.statusCode == 200) {
        final entryJson = json.decode(response.body);
        return FuelEntry(
          id: entryJson['id']?.toString() ?? entryId,
          liters: double.parse(entryJson['liters']?.toString() ?? '0'),
          pricePerLiter: double.parse(entryJson['price_per_liter']?.toString() ?? '0'),
          totalCost: double.parse(entryJson['total_cost']?.toString() ?? '0'),
          dateTime: DateTime.parse(entryJson['date_time']),
          odometerReading: entryJson['odometer_reading'] != null
              ? double.parse(entryJson['odometer_reading'].toString())
              : null,
        );
      } else if (response.statusCode == 404) {
        return null; // Entry not found
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to get entry from server');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('TimeoutException')) {
        throw Exception('Cannot connect to server. Please check your internet connection.');
      }
      rethrow;
    }
  }
}
