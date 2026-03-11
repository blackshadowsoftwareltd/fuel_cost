import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/theme_service.dart';

class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(ThemeState()) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final mode = await ThemeService.getThemeMode();
    final color = await ThemeService.getAccentColor();
    state = ThemeState(themeMode: mode, accentColor: color);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await ThemeService.setThemeMode(mode);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setAccentColor(Color color) async {
    await ThemeService.setAccentColor(color);
    state = state.copyWith(accentColor: color);
  }
}

class ThemeState {
  final ThemeMode themeMode;
  final Color accentColor;

  ThemeState({
    this.themeMode = ThemeMode.system,
    this.accentColor = const Color(0xFF2196F3),
  });

  ThemeState copyWith({ThemeMode? themeMode, Color? accentColor}) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
    );
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});
