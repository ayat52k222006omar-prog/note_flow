import 'package:flutter/material.dart';

class AppColors {
  // ألوان الوضع الفاتح
  static const Color background = Color(0xFFF3EFEA);
  static const Color primaryDark = Color(0xFF2E3A4B);
  static const Color slateBlue = Color(0xFF738598);
  static const Color warmSand = Color(0xFFDCD3C6);
  static const Color softLavender = Color(0xFFC9C4D8);
  static const Color cardWhite = Color(0xFFFAF8F5);
  static const Color textPrimary = Color(0xFF232B35);
  static const Color textSecondary = Color(0xFF6E7781);

  // ألوان الوضع المظلم المستوحاة من التصميم المرفق
  static const Color darkBackground = Color(0xFF0B0D17);
  static const Color darkSurface = Color(0xFF121526);
  static const Color darkCard = Color(0xFF171A2E);
  static const Color darkElevatedCard = Color(0xFF1F233D);
  static const Color darkAccentPurple = Color(0xFF7C6CF0);
  static const Color darkAccentLavender = Color(0xFF9688F5);
  static const Color darkTextPrimary = Color(0xFFF5F6FA);
  static const Color darkTextSecondary = Color(0xFF9BA3C2);
  static const Color darkBorder = Color(0xFF282E4E);
}

extension ThemeColorsX on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get bgColor =>
      isDarkMode ? AppColors.darkBackground : AppColors.background;

  Color get surfaceColor =>
      isDarkMode ? AppColors.darkSurface : AppColors.cardWhite;

  Color get cardColor =>
      isDarkMode ? AppColors.darkCard : AppColors.cardWhite;

  Color get elevatedCardColor =>
      isDarkMode ? AppColors.darkElevatedCard : AppColors.warmSand;

  Color get primaryTextColor =>
      isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary;

  Color get secondaryTextColor =>
      isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary;

  Color get accentColor =>
      isDarkMode ? AppColors.darkAccentPurple : AppColors.primaryDark;

  Color get borderColor =>
      isDarkMode ? AppColors.darkBorder : Colors.transparent;
}

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primaryDark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryDark,
          brightness: Brightness.light,
          surface: AppColors.background,
        ),
        cardTheme: CardThemeData(
          color: AppColors.cardWhite,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.cardWhite,
          selectedItemColor: AppColors.primaryDark,
          unselectedItemColor: AppColors.textSecondary,
          type: BottomNavigationBarType.fixed,
          elevation: 4,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.textPrimary),
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkBackground,
        primaryColor: AppColors.darkAccentPurple,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.darkAccentPurple,
          onPrimary: Colors.white,
          secondary: AppColors.darkAccentLavender,
          onSecondary: Colors.white,
          surface: AppColors.darkSurface,
          onSurface: AppColors.darkTextPrimary,
          outline: AppColors.darkBorder,
        ),
        canvasColor: AppColors.darkSurface,
        cardColor: AppColors.darkCard,
        dividerColor: AppColors.darkBorder,
        cardTheme: CardThemeData(
          color: AppColors.darkCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.darkBorder, width: 1),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.darkSurface,
          selectedItemColor: AppColors.darkAccentPurple,
          unselectedItemColor: AppColors.darkTextSecondary,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.darkAccentPurple,
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkCard,
          hintStyle: const TextStyle(color: AppColors.darkTextSecondary),
          labelStyle: const TextStyle(color: AppColors.darkTextSecondary),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.darkBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.darkAccentPurple, width: 1.5),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.darkAccentPurple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
          titleTextStyle: TextStyle(
            color: AppColors.darkTextPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
}