import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  ThemeService._private();
  static final ThemeService instance = ThemeService._private();

  static const _prefsKey = 'theme_mode';

  final ValueNotifier<ThemeMode> modeNotifier = ValueNotifier(ThemeMode.system);

  ThemeMode get mode => modeNotifier.value;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefsKey);
    if (stored == null) {
      modeNotifier.value = ThemeMode.system;
      return;
    }
    modeNotifier.value = _modeFromString(stored);
  }

  Future<void> setTheme(ThemeMode mode) async {
    modeNotifier.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, _stringFromMode(mode));
  }

  Future<void> toggle() async {
    final newMode = modeNotifier.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setTheme(newMode);
  }

  ThemeMode _modeFromString(String s) {
    switch (s) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _stringFromMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      default:
        return 'system';
    }
  }
}
