import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _keyThemeMode = 'theme_mode';

class ThemeState {
  final ThemeMode themeMode;
  const ThemeState({this.themeMode = ThemeMode.dark});
}

class ThemeNotifier extends Notifier<ThemeState> {
  static const _storage = FlutterSecureStorage(aOptions: AndroidOptions());

  @override
  ThemeState build() {
    _loadSaved();
    return const ThemeState();
  }

  Future<void> _loadSaved() async {
    try {
      final saved = await _storage.read(key: _keyThemeMode);
      if (saved == 'light') {
        state = const ThemeState(themeMode: ThemeMode.light);
      } else {
        state = const ThemeState(themeMode: ThemeMode.dark);
      }
    } catch (_) {
      // Varsayilan dark tema
    }
  }

  Future<void> toggleTheme() async {
    final newMode = state.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = ThemeState(themeMode: newMode);
    try {
      await _storage.write(key: _keyThemeMode, value: newMode == ThemeMode.light ? 'light' : 'dark');
    } catch (_) {}
  }

  bool get isDark => state.themeMode == ThemeMode.dark;
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeState>(() => ThemeNotifier());
