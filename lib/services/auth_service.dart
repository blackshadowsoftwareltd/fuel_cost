import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constraints.dart';
import '../providers/auth_provider.dart';
import '../providers/fuel_entries_provider.dart';
import '../providers/sync_provider.dart';
import '../screens/auth_screen.dart' show AuthScreen;
import 'http_client_service.dart';

class AuthService {
  static Future<void> handleSync(BuildContext c, WidgetRef ref) async {
    final isAuthenticated = ref.read(authenticationProvider).value ?? false;

    if (!isAuthenticated) {
      // Navigate to sign in screen
      final result = await Navigator.push(c, MaterialPageRoute(builder: (context) => const AuthScreen()));

      // If sign in was successful, immediately sync
      if (result == true) {
        await ref.read(authenticationProvider.notifier).refresh();
        final newAuthState = ref.read(authenticationProvider).value ?? false;
        if (newAuthState) {
          await _performSync(c, ref);
        }
      }
    } else {
      // User is already signed in, just sync
      await _performSync(c, ref);
    }
  }

  static Future<void> _performSync(BuildContext c, WidgetRef ref) async {
    try {
      // Use the proper sync provider instead of direct fuel entries sync
      await ref.read(syncStatusProvider.notifier).performSync();
      // Refresh fuel entries after sync
      await ref.read(fuelEntriesProvider.notifier).refresh();

      if (c.mounted) {
        ScaffoldMessenger.of(
          c,
        ).showSnackBar(const SnackBar(content: Text('Data synced successfully!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (c.mounted) {
        ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text('Sync failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';

  static Future<Map<String, dynamic>> signIn({required String email, required String password}) async {
    try {
      final url = '$baseUrl/api/auth/signin';
      debugPrint('DEBUG: Attempting sign-in to: $url');
      debugPrint('DEBUG: Email: $email');

      final response = await HttpClientService.client
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('DEBUG: Response status: ${response.statusCode}');
      debugPrint('DEBUG: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        await _saveAuthData(userId: data['user_id']?.toString() ?? '', email: email);

        return data;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Authentication failed');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('TimeoutException')) {
        throw Exception('Cannot connect to server. Please check your internet connection.');
      }
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await HttpClientService.client
          .post(
            Uri.parse('$baseUrl/api/auth/signup'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'email': email, 'password': password, 'name': name}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        await _saveAuthData(userId: data['user_id']?.toString() ?? '', email: email);

        return data;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Registration failed');
      }
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('TimeoutException')) {
        throw Exception('Cannot connect to server. Please check your internet connection.');
      }
      rethrow;
    }
  }

  static Future<void> _saveAuthData({required String userId, required String email}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_userEmailKey, email);
  }

  static Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_userIdKey);
    return userId != null && userId.isNotEmpty;
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  static Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_userEmailKey);
  }

  static Map<String, String> getAuthHeaders() {
    return {'Content-Type': 'application/json'};
  }
}
