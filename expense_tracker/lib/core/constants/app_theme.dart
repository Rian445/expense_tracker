import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color primaryLight = Color(0xFF818CF8);
  
  // Accents
  static const Color accent = Color(0xFFF43F5E); // Rose
  static const Color secondary = Color(0xFF10B981); // Emerald
  
  // Neutral
  static const Color background = Color(0xFFF8FAFC);
  static const Color card = Colors.white;
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        surface: AppColors.background,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.background,
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        surface: const Color(0xFF0F172A),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E293B),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(color: Color(0xFF94A3B8)),
      ),
    );
  }
}
