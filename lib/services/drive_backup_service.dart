import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fuel_storage_service.dart';

class DriveBackupService {
  static const String _backupFileName = 'fuel_cost_backup.csv';
  static const String _lastBackupTimeKey = 'last_drive_backup_time';
  static const String _driveFileIdKey = 'drive_backup_file_id';
  static const String _autoBackupKey = 'auto_backup_enabled';

  static Future<bool> isAutoBackupEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoBackupKey) ?? false;
  }

  static Future<void> setAutoBackup(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoBackupKey, enabled);
  }

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveAppdataScope],
  );

  // --- Sign-In ---

  static Future<GoogleSignInAccount?> signIn() async {
    try {
      return await _googleSignIn.signIn();
    } on PlatformException catch (e) {
      // print works in release mode (visible via `adb logcat | grep flutter`)
      print('Google Sign-In PlatformException: code=${e.code}, message=${e.message}, details=${e.details}');
      throw Exception('Google Sign-In failed: ${e.message ?? e.code}');
    } catch (e) {
      print('Google Sign-In error: $e');
      rethrow;
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_driveFileIdKey);
    await prefs.remove(_lastBackupTimeKey);
  }

  static Future<bool> isSignedIn() async {
    try {
      return _googleSignIn.currentUser != null ||
          await _googleSignIn.signInSilently() != null;
    } catch (e) {
      print('Google Sign-In check failed: $e');
      return false;
    }
  }

  static GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  // --- Authenticated Drive Client ---

  static Future<drive.DriveApi> _getDriveApi() async {
    final account =
        _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
    if (account == null) throw Exception('Not signed in to Google');

    final authClient = await _googleSignIn.authenticatedClient();
    if (authClient == null) {
      throw Exception('Failed to get authenticated client');
    }

    return drive.DriveApi(authClient);
  }

  // --- Backup (Upload) ---

  static Future<void> backupToDrive() async {
    final driveApi = await _getDriveApi();
    final csvContent = await FuelStorageService.exportToCsv();
    final bytes = utf8.encode(csvContent);
    final media = drive.Media(Stream.value(bytes), bytes.length);

    final prefs = await SharedPreferences.getInstance();
    final existingFileId = prefs.getString(_driveFileIdKey);

    if (existingFileId != null) {
      try {
        // Update existing file
        await driveApi.files.update(
          drive.File()..name = _backupFileName,
          existingFileId,
          uploadMedia: media,
        );
      } catch (e) {
        // File might have been deleted, clear stored ID and create new
        print('Update failed, creating new file: $e');
        await prefs.remove(_driveFileIdKey);
        await _createNewBackup(driveApi, media, prefs);
      }
    } else {
      await _createNewBackup(driveApi, media, prefs);
    }

    await _setLastBackupTime();
  }

  static Future<void> _createNewBackup(
    drive.DriveApi driveApi,
    drive.Media media,
    SharedPreferences prefs,
  ) async {
    final driveFile = drive.File()
      ..name = _backupFileName
      ..parents = ['appDataFolder'];
    final result = await driveApi.files.create(driveFile, uploadMedia: media);
    if (result.id != null) {
      await prefs.setString(_driveFileIdKey, result.id!);
    }
  }

  // --- Restore (Download) ---

  static Future<int> restoreFromDrive() async {
    final driveApi = await _getDriveApi();

    // Find backup file in appDataFolder
    final fileList = await driveApi.files.list(
      spaces: 'appDataFolder',
      q: "name = '$_backupFileName'",
      $fields: 'files(id, name, modifiedTime)',
    );

    if (fileList.files == null || fileList.files!.isEmpty) {
      throw Exception('No backup found on Google Drive');
    }

    final fileId = fileList.files!.first.id!;

    // Download file content
    final media = await driveApi.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final bytes = <int>[];
    await for (final chunk in media.stream) {
      bytes.addAll(chunk);
    }
    final csvContent = utf8.decode(bytes);

    // Clear existing entries and import
    await FuelStorageService.clearFuelEntries();
    return await FuelStorageService.importFromCsv(csvContent);
  }

  // --- Metadata ---

  static Future<DateTime?> getLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeStr = prefs.getString(_lastBackupTimeKey);
    if (timeStr != null) {
      return DateTime.tryParse(timeStr);
    }
    return null;
  }

  static Future<DateTime?> getRemoteBackupTime() async {
    try {
      final driveApi = await _getDriveApi();
      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = '$_backupFileName'",
        $fields: 'files(id, modifiedTime)',
      );
      if (fileList.files != null && fileList.files!.isNotEmpty) {
        return fileList.files!.first.modifiedTime;
      }
    } catch (e) {
      print('Failed to get remote backup time: $e');
    }
    return null;
  }

  static Future<void> _setLastBackupTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _lastBackupTimeKey,
      DateTime.now().toIso8601String(),
    );
  }
}
