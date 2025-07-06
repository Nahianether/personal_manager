import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppTheme {
  light('Light', Icons.light_mode),
  dark('Dark', Icons.dark_mode),
  auto('Auto', Icons.brightness_auto);

  const AppTheme(this.label, this.icon);
  final String label;
  final IconData icon;
}

class ThemeState {
  final AppTheme currentTheme;
  final ThemeData themeData;

  ThemeState({
    required this.currentTheme,
    required this.themeData,
  });

  ThemeState copyWith({
    AppTheme? currentTheme,
    ThemeData? themeData,
  }) {
    return ThemeState(
      currentTheme: currentTheme ?? this.currentTheme,
      themeData: themeData ?? this.themeData,
    );
  }

  // Keep backward compatibility
  bool get isDarkMode => currentTheme == AppTheme.dark;
}

class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(ThemeState(currentTheme: AppTheme.light, themeData: _lightTheme)) {
    _loadTheme();
  }

  static const String _themeKey = 'app_theme';

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_themeKey);
    
    AppTheme selectedTheme = AppTheme.light;
    if (themeString != null) {
      try {
        selectedTheme = AppTheme.values.firstWhere((theme) => theme.name == themeString);
      } catch (e) {
        // If saved theme is not found, default to light
        selectedTheme = AppTheme.light;
      }
    }
    
    _updateTheme(selectedTheme);
  }

  Future<void> setTheme(AppTheme theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme.name);
    _updateTheme(theme);
  }

  void _updateTheme(AppTheme theme) {
    ThemeData themeData;
    
    switch (theme) {
      case AppTheme.light:
        themeData = _lightTheme;
        break;
      case AppTheme.dark:
        themeData = _darkTheme;
        break;
      case AppTheme.auto:
        // For auto mode, you could check system brightness
        // For now, defaulting to light - you can enhance this later
        final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
        themeData = brightness == Brightness.dark ? _darkTheme : _lightTheme;
        break;
    }
    
    state = ThemeState(
      currentTheme: theme,
      themeData: themeData,
    );
  }

  // Keep backward compatibility
  Future<void> toggleTheme() async {
    final newTheme = state.currentTheme == AppTheme.light ? AppTheme.dark : AppTheme.light;
    await setTheme(newTheme);
  }

  static final _lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF1A73E8),
      secondary: Color(0xFF34A853),
      tertiary: Color(0xFFFF6B35),
      surface: Color(0xFFF8F9FA),
      surfaceContainer: Colors.white,
      surfaceContainerHighest: Color(0xFFF1F3F4),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF202124),
      onSurfaceVariant: Color(0xFF5F6368),
      outline: Color(0xFFDADCE0),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF202124),
      elevation: 0,
      scrolledUnderElevation: 1,
      titleTextStyle: TextStyle(
        color: Color(0xFF202124),
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Color(0xFF202124),
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: Color(0xFF202124),
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: Color(0xFF202124),
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Color(0xFF202124),
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: Color(0xFF202124),
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Color(0xFF5F6368),
      ),
    ),
  );

  static final _darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF4285F4),
      secondary: Color(0xFF34A853),
      tertiary: Color(0xFFFF6B35),
      surface: Color(0xFF121212),
      surfaceContainer: Color(0xFF1E1E1E),
      surfaceContainerHighest: Color(0xFF2C2C2C),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFFE8EAED),
      onSurfaceVariant: Color(0xFF9AA0A6),
      outline: Color(0xFF5F6368),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Color(0xFFE8EAED),
      elevation: 0,
      scrolledUnderElevation: 1,
      titleTextStyle: TextStyle(
        color: Color(0xFFE8EAED),
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E1E1E),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4285F4),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Color(0xFFE8EAED),
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: Color(0xFFE8EAED),
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: Color(0xFFE8EAED),
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Color(0xFFE8EAED),
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: Color(0xFFE8EAED),
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Color(0xFF9AA0A6),
      ),
    ),
  );
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});