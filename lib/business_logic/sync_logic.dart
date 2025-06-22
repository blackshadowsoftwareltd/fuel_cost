import 'package:flutter/foundation.dart';

import '../services/sync_service.dart';
import '../services/auth_service.dart';
import '../models/fuel_entry.dart';

class SyncLogic {
  /// Perform full synchronization with server
  static Future<void> performFullSync() async {
    final isAuthenticated = await AuthService.isAuthenticated();
    if (!isAuthenticated) {
      throw Exception('User not authenticated');
    }

    await SyncService.fullSync();
  }

  /// Upload a single entry to server
  static Future<void> uploadEntry(FuelEntry entry) async {
    final isAuthenticated = await AuthService.isAuthenticated();
    if (!isAuthenticated) {
      // Don't throw error, just skip upload
      return;
    }

    try {
      await SyncService.uploadEntry(entry);
    } catch (e) {
      // Log error but don't throw, allow offline operation
      debugPrint('Failed to upload entry: $e');
    }
  }

  /// Delete entry from server
  static Future<void> deleteEntryFromServer(String entryId) async {
    final isAuthenticated = await AuthService.isAuthenticated();
    if (!isAuthenticated) {
      // Don't throw error, just skip server deletion
      return;
    }

    try {
      await SyncService.deleteEntryFromServer(entryId);
    } catch (e) {
      // Log error but don't throw, allow offline operation
      debugPrint('Failed to delete entry from server: $e');
    }
  }

  /// Get last sync time
  static Future<DateTime?> getLastSyncTime() async {
    return await SyncService.getLastFullSync();
  }

  /// Format sync time for display
  static String formatSyncTime(DateTime? lastSync) {
    return SyncService.formatLastSyncTime(lastSync);
  }

  /// Check if sync is needed (more than 1 hour since last sync)
  static Future<bool> isSyncNeeded() async {
    final lastSync = await getLastSyncTime();
    if (lastSync == null) return true;

    final now = DateTime.now();
    final difference = now.difference(lastSync);
    return difference.inHours >= 1;
  }
}
