import '../services/auth_service.dart';
import '../services/sync_service.dart';

class AuthLogic {
  /// Handle user sign in with error handling
  static Future<void> signIn(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email and password are required');
    }
    
    if (!_isValidEmail(email)) {
      throw Exception('Please enter a valid email address');
    }
    
    await AuthService.signIn(email: email, password: password);
  }

  /// Handle user sign up with validation
  static Future<void> signUp(String email, String password, String name) async {
    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      throw Exception('All fields are required');
    }
    
    if (!_isValidEmail(email)) {
      throw Exception('Please enter a valid email address');
    }
    
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }
    
    await AuthService.signUp(email: email, password: password, name: name);
  }

  /// Handle user sign out
  static Future<void> signOut() async {
    await AuthService.signOut();
    // Clear sync times when signing out
    await SyncService.clearAllSyncTimes();
  }

  /// Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    return await AuthService.isAuthenticated();
  }

  /// Get current user ID
  static Future<String?> getCurrentUserId() async {
    return await AuthService.getUserId();
  }

  /// Validate email format
  static bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}