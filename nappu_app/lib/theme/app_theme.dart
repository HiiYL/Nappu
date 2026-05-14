import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color background = Color(0xFF0a0e1a);
  static const Color surface = Color(0xFF131831);
  static const Color surfaceLight = Color(0xFF1a2040);
  static const Color card = Color(0xFF161d36);
  static const Color cardBorder = Color(0xFF252d50);
  static const Color primary = Color(0xFF6c63ff);
  static const Color accent = Color(0xFF7b6ff0);
  static const Color gold = Color(0xFFf5a623);
  static const Color goldLight = Color(0xFFffc857);
  static const Color green = Color(0xFF4cd964);
  static const Color greenDark = Color(0xFF2d8a4e);
  static const Color red = Color(0xFFff4757);
  static const Color blue = Color(0xFF4a9eff);
  static const Color purple = Color(0xFF9b59b6);
  static const Color pink = Color(0xFFe84393);
  static const Color textPrimary = Color(0xFFf0f0f0);
  static const Color textSecondary = Color(0xFF8e94b0);
  static const Color textMuted = Color(0xFF5a6080);
  static const Color navBar = Color(0xFF0d1225);
  static const Color streakOrange = Color(0xFFff6b35);
  static const Color sleepGood = Color(0xFF4cd964);
  static const Color sleepOther = Color(0xFF4a6fa5);
  static const Color gradientStart = Color(0xFF6c5ce7);
  static const Color gradientEnd = Color(0xFF74b9ff);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.navBar,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
