import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores and broadcasts the app's ThemeMode.
/// Persists the selection to SharedPreferences so it survives restarts.
class ThemeNotifier extends ChangeNotifier {
  static const _key = 'app_theme_mode';

  ThemeMode _mode;

  ThemeNotifier(this._mode);

  ThemeMode get themeMode => _mode;

  bool get isDark => _mode == ThemeMode.dark;

  static Future<ThemeNotifier> create() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    ThemeMode mode = ThemeMode.light;
    if (saved == 'dark') mode = ThemeMode.dark;
    return ThemeNotifier(mode);
  }

  Future<void> toggle() async {
    _mode = _mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _mode == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _mode == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }
}
