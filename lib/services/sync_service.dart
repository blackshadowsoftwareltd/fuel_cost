import 'dart:convert'; 
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
    // API calls commented out
    // final userId = await AuthService.getUserId();
    // if (userId == null) {
    //   throw Exception('User not authenticated');
    // }
    //
    // try {
    //   final localEntries = await FuelStorageService.getFuelEntries();
    //   if (localEntries.isEmpty) {
    //     debugPrint('No local entries to sync');
    //     return;
    //   }
    //   final bulkData = localEntries.map((entry) {
    //     final entryMap = <String, dynamic>{
    //       'liters': entry.liters,
    //       'price_per_liter': entry.pricePerLiter,
    //       'total_cost': entry.totalCost,
    //       'date_time': entry.dateTime.toUtc().toIso8601String(),
    //     };
    //     if (entry.odometerReading != null) {
    //       entryMap['odometer_reading'] = entry.odometerReading;
    //     }
    //     return entryMap;
    //   }).toList();
    //   debugPrint(bulkData.toString());
    //   final headers = AuthService.getAuthHeaders();
    //   final requestBody = json.encode({'user_id': userId, 'entries': bulkData});
    //   debugPrint('Sync request body: $requestBody');
    //   final response = await HttpClientService.client.post(
    //     Uri.parse('$baseUrl/api/fuel-entries/bulk'),
    //     headers: headers,
    //     body: requestBody,
    //   );
    //   debugPrint('Sync response: ${response.statusCode} - ${response.body}');
    //   if (response.statusCode == 200 || response.statusCode == 201) {
    //     await _setLastUploadSync();
    //     return;
    //   } else {
    //     final errorMessage = ErrorUtils.extractErrorFromResponse(response.body, response.statusCode);
    //     throw Exception(errorMessage);
    //   }
    // } catch (e) {
    //   if (ErrorUtils.isNetworkError(e.toString())) {
    //     throw Exception(ErrorUtils.getNetworkErrorMessage());
    //   }
    //   rethrow;
    // }
    debugPrint('API calls disabled');
  }

  static Future<List<FuelEntry>> downloadFromServer() async {
    // API calls commented out
    // final userId = await AuthService.getUserId();
    // if (userId == null) {
    //   throw Exception('User not authenticated');
    // }
    //
    // try {
    //   final headers = AuthService.getAuthHeaders();
    //   final response = await HttpClientService.client.get(
    //     Uri.parse('$baseUrl/api/fuel-entries/$userId'),
    //     headers: headers,
    //   );
    //   if (response.statusCode == 200) {
    //     final List<dynamic> entriesJson = json.decode(response.body);
    //     await _setLastDownloadSync();
    //     return entriesJson.map((entryJson) {
    //       return FuelEntry(
    //         id: entryJson['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
    //         liters: double.parse(entryJson['liters']?.toString() ?? '0'),
    //         pricePerLiter: double.parse(entryJson['price_per_liter']?.toString() ?? '0'),
    //         totalCost: double.parse(entryJson['total_cost']?.toString() ?? '0'),
    //         dateTime: DateTime.parse(entryJson['date_time']).toLocal(),
    //         odometerReading: entryJson['odometer_reading'] != null
    //             ? double.parse(entryJson['odometer_reading'].toString())
    //             : null,
    //       );
    //     }).toList();
    //   } else {
    //     final errorMessage = ErrorUtils.extractErrorFromResponse(response.body, response.statusCode);
    //     throw Exception(errorMessage);
    //   }
    // } catch (e) {
    //   if (ErrorUtils.isNetworkError(e.toString())) {
    //     throw Exception(ErrorUtils.getNetworkErrorMessage());
    //   }
    //   rethrow;
    // }
    debugPrint('API calls disabled');
    return [];
  }

  static Future<void> fullSync() async {
    // API calls commented out
    // final userId = await AuthService.getUserId();
    // if (userId == null) {
    //   throw Exception('User not authenticated');
    // }
    //
    // try {
    //   await syncWithServer();
    //   final serverEntries = await downloadFromServer();
    //   final localEntries = await FuelStorageService.getFuelEntries();
    //   final localEntryMap = <String, FuelEntry>{};
    //   for (final entry in localEntries) {
    //     final key = '${entry.dateTime.millisecondsSinceEpoch}_${entry.liters}_${entry.totalCost}';
    //     localEntryMap[key] = entry;
    //   }
    //   for (final serverEntry in serverEntries) {
    //     final key = '${serverEntry.dateTime.millisecondsSinceEpoch}_${serverEntry.liters}_${serverEntry.totalCost}';
    //     if (!localEntryMap.containsKey(key)) {
    //       await FuelStorageService.saveFuelEntry(serverEntry);
    //     }
    //   }
    //   await _setLastFullSync();
    // } catch (e) {
    //   rethrow;
    // }
    debugPrint('API calls disabled');
  }

  static Future<void> uploadEntry(FuelEntry entry) async {
    // API calls commented out
    debugPrint('API calls disabled - uploadEntry skipped');
  }

  static Future<void> deleteEntryFromServer(String entryId) async {
    // API calls commented out
    debugPrint('API calls disabled - deleteEntryFromServer skipped');
  }

  static Future<void> bulkDeleteFromServer(List<String> entryIds) async {
    // API calls commented out
    debugPrint('API calls disabled - bulkDeleteFromServer skipped');
  }

  static Future<void> updateEntryOnServer(FuelEntry entry) async {
    // API calls commented out
    debugPrint('API calls disabled - updateEntryOnServer skipped');
  }

  static Future<FuelEntry?> getSpecificEntry(String entryId) async {
    // API calls commented out
    debugPrint('API calls disabled - getSpecificEntry skipped');
    return null;
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
