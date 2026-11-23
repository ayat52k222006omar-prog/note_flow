import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AppThemeController {
  AppThemeController._();
  static final AppThemeController instance = AppThemeController._();

  static const String _boxName = 'settings_box';
  static const String _darkKey = 'is_dark_mode';

  final ValueNotifier<ThemeMode> themeMode = ValueNotifier<ThemeMode>(ThemeMode.light);

  Future<void> init() async {
    final box = await Hive.openBox(_boxName);
    final isDark = box.get(_darkKey, defaultValue: false) as bool;
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  bool get isDark => themeMode.value == ThemeMode.dark;

  Future<void> toggleDarkMode() async {
    final nextDark = !isDark;
    themeMode.value = nextDark ? ThemeMode.dark : ThemeMode.light;
    final box = Hive.isBoxOpen(_boxName)
        ? Hive.box(_boxName)
        : await Hive.openBox(_boxName);
    await box.put(_darkKey, nextDark);
  }
}