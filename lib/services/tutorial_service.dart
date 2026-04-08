import 'package:shared_preferences/shared_preferences.dart';

class TutorialService {
  static const String _onboardingKey = 'onboarding_completed';
  static const String _tourKey = 'tour_completed';

  // ─── Onboarding (carousel shown on first launch) ───
  static Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  static Future<void> setOnboardingCompleted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, value);
  }

  // ─── Showcase tour (spotlights on the home screen) ───
  static Future<bool> isTourCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tourKey) ?? false;
  }

  static Future<void> setTourCompleted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tourKey, value);
  }

  /// Reset everything — used when the user taps "Replay Tutorial"
  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_onboardingKey);
    await prefs.remove(_tourKey);
  }
}
