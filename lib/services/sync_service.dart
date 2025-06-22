import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constraints.dart';
import '../models/fuel_entry.dart';
import '../utils/error_utils.dart';
import './auth_service.dart';
import './fuel_storage_service.dart';
import './http_client_service.dart';

class SyncService {
  static const String _lastUploadSyncKey = 'last_upload_sync_time';
  static const String _lastDownloadSyncKey = 'last_download_sync_time';
  static const String _lastFullSyncKey = 'last_full_sync_time';

  static Future<void> syncWithServer() async {
    final userId = await AuthService.getUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get local fuel entries
      final localEntries = await FuelStorageService.getFuelEntries();

      if (localEntries.isEmpty) {
        debugPrint('No local entries to sync');
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
      debugPrint(bulkData.toString());
      // Upload bulk data to server
      final headers = AuthService.getAuthHeaders();
      final requestBody = json.encode({'user_id': userId, 'entries': bulkData});

      // Debug: debugPrint the request body
      debugPrint('Sync request body: $requestBody');

      final response = await HttpClientService.client.post(
        Uri.parse('$baseUrl/api/fuel-entries/bulk'),
        headers: headers,
        body: requestBody,
      );

      debugPrint('Sync response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Sync successful - record upload sync time
        await _setLastUploadSync();
        return;
      } else {
        final errorMessage = ErrorUtils.extractErrorFromResponse(response.body, response.statusCode);
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (ErrorUtils.isNetworkError(e.toString())) {
        throw Exception(ErrorUtils.getNetworkErrorMessage());
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
      final response = await HttpClientService.client.get(
        Uri.parse('$baseUrl/api/fuel-entries/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> entriesJson = json.decode(response.body);

        // Record download sync time
        await _setLastDownloadSync();

        return entriesJson.map((entryJson) {
          return FuelEntry(
            id: entryJson['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
            liters: double.parse(entryJson['liters']?.toString() ?? '0'),
            pricePerLiter: double.parse(entryJson['price_per_liter']?.toString() ?? '0'),
            totalCost: double.parse(entryJson['total_cost']?.toString() ?? '0'),
            dateTime: DateTime.parse(entryJson['date_time']).toLocal(),
            odometerReading: entryJson['odometer_reading'] != null
                ? double.parse(entryJson['odometer_reading'].toString())
                : null,
          );
        }).toList();
      } else {
        final errorMessage = ErrorUtils.extractErrorFromResponse(response.body, response.statusCode);
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (ErrorUtils.isNetworkError(e.toString())) {
        throw Exception(ErrorUtils.getNetworkErrorMessage());
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

      // Record full sync time
      await _setLastFullSync();
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

      // Debug: debugPrint the request body
      debugPrint('Upload entry request body: $requestBody');

      final response = await HttpClientService.client.post(
        Uri.parse('$baseUrl/api/fuel-entries'),
        headers: headers,
        body: requestBody,
      );

      debugPrint('Upload entry response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Upload successful - record upload sync time
        await _setLastUploadSync();
      } else {
        final errorMessage = ErrorUtils.extractErrorFromResponse(response.body, response.statusCode);
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (ErrorUtils.isNetworkError(e.toString())) {
        throw Exception(ErrorUtils.getNetworkErrorMessage());
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
      debugPrint('Attempting to delete entry: $entryId for user: $userId');
      debugPrint('DELETE URL: $baseUrl/api/fuel-entries/$userId/$entryId');

      final response = await HttpClientService.client.delete(
        Uri.parse('$baseUrl/api/fuel-entries/$userId/$entryId'),
        headers: headers,
      );

      debugPrint('Delete response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Success - entry deleted from server
        return;
      } else if (response.statusCode == 404) {
        // Entry not found on server - this is OK, it means it was already deleted or never synced
        debugPrint('Entry not found on server, treating as successful delete');
        return;
      } else if (response.statusCode == 405) {
        // Method not allowed - server doesn't support delete endpoint
        throw Exception('Server does not support delete functionality yet. Entry removed locally only.');
      } else {
        // Other error
        final errorMessage = ErrorUtils.extractErrorFromResponse(response.body, response.statusCode);
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (ErrorUtils.isNetworkError(e.toString())) {
        throw Exception('Cannot connect to server. Entry deleted locally only.');
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
      final response = await HttpClientService.client.post(
        Uri.parse('$baseUrl/api/fuel-entries/bulk/delete'),
        headers: headers,
        body: json.encode({'user_id': userId, 'entry_ids': entryIds}),
      );

      if (response.statusCode != 200) {
        final errorMessage = ErrorUtils.extractErrorFromResponse(response.body, response.statusCode);
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (ErrorUtils.isNetworkError(e.toString())) {
        throw Exception(ErrorUtils.getNetworkErrorMessage());
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
      final response = await HttpClientService.client.put(
        Uri.parse('$baseUrl/api/fuel-entries/$userId/${entry.id}'),
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
        final errorMessage = ErrorUtils.extractErrorFromResponse(response.body, response.statusCode);
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (ErrorUtils.isNetworkError(e.toString())) {
        throw Exception(ErrorUtils.getNetworkErrorMessage());
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
      final response = await HttpClientService.client.get(
        Uri.parse('$baseUrl/api/fuel-entries/$userId/$entryId'),
        headers: headers,
      );

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
        final errorMessage = ErrorUtils.extractErrorFromResponse(response.body, response.statusCode);
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (ErrorUtils.isNetworkError(e.toString())) {
        throw Exception(ErrorUtils.getNetworkErrorMessage());
      }
      rethrow;
    }
  }

  // Last sync time management methods
  static Future<void> _setLastUploadSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastUploadSyncKey, DateTime.now().toIso8601String());
  }

  static Future<void> _setLastDownloadSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastDownloadSyncKey, DateTime.now().toIso8601String());
  }

  static Future<void> _setLastFullSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastFullSyncKey, DateTime.now().toIso8601String());
  }

  static Future<DateTime?> getLastUploadSync() async {
    final prefs = await SharedPreferences.getInstance();
    final timeString = prefs.getString(_lastUploadSyncKey);
    if (timeString == null) return null;
    try {
      return DateTime.parse(timeString);
    } catch (e) {
      return null;
    }
  }

  static Future<DateTime?> getLastDownloadSync() async {
    final prefs = await SharedPreferences.getInstance();
    final timeString = prefs.getString(_lastDownloadSyncKey);
    if (timeString == null) return null;
    try {
      return DateTime.parse(timeString);
    } catch (e) {
      return null;
    }
  }

  static Future<DateTime?> getLastFullSync() async {
    final prefs = await SharedPreferences.getInstance();
    final timeString = prefs.getString(_lastFullSyncKey);
    if (timeString == null) return null;
    try {
      return DateTime.parse(timeString);
    } catch (e) {
      return null;
    }
  }

  static String formatLastSyncTime(DateTime? lastSync) {
    if (lastSync == null) return 'Never';

    final now = DateTime.now();
    final difference = now.difference(lastSync);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${lastSync.day}/${lastSync.month}/${lastSync.year}';
    }
  }

  static Future<void> clearAllSyncTimes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastUploadSyncKey);
    await prefs.remove(_lastDownloadSyncKey);
    await prefs.remove(_lastFullSyncKey);
  }
}
