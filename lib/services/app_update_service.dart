import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

class AppUpdateService {
  /// Check for updates and prompt the user if available.
  /// Call this once from the home screen's initState.
  static Future<void> checkForUpdate(BuildContext context) async {
    // Only works on Android
    if (!Platform.isAndroid) return;

    try {
      final info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        // If it's a high-priority update (priority >= 4), force immediate update
        if (info.updatePriority >= 4) {
          await InAppUpdate.performImmediateUpdate();
        } else {
          // Otherwise, use flexible (background) update
          await InAppUpdate.startFlexibleUpdate();
          // Once downloaded, install it
          await InAppUpdate.completeFlexibleUpdate();
        }
      }
    } catch (e) {
      debugPrint('In-app update check failed: $e');
    }
  }
}
