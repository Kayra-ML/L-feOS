import 'package:flutter/material.dart';

/// LifeOS web arayüzündeki koyu tema paleti (frontend/index.html) ile
/// aynı hissi verecek renkler.
class AppColors {
  AppColors._();

  static const bg = Color(0xFF040406);
  static const panel = Color(0xFF0A0A0D);
  static const panel2 = Color(0xFF0D0D11);
  static const line = Color(0xFF1B1B20);
  static const text = Color(0xFFE8E8E6);
  static const textDim = Color(0xFF9A9AA2);
  static const textFaint = Color(0xFF55555C);

  static const aiPurple = Color(0xFFA855F7);
  static const aiPurpleDark = Color(0xFF7C3AED);
  static const success = Color(0xFF10B981);
  static const danger = Color(0xFFEF4444);
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.aiPurple,
        secondary: AppColors.success,
        surface: AppColors.panel,
        error: AppColors.danger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.text,
        elevation: 0,
        centerTitle: false,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.panel,
      ),
      cardTheme: CardThemeData(
        color: AppColors.panel2,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.text,
        displayColor: AppColors.text,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.panel2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.aiPurple),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.aiPurple,
        foregroundColor: Colors.white,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.panel2,
        contentTextStyle: TextStyle(color: AppColors.text),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.line),
    );
  }
}
