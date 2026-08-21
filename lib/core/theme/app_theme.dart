import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static SnackBarThemeData _snackBarTheme(ColorScheme colorScheme) =>
      SnackBarThemeData(
        backgroundColor: colorScheme.primary,
        contentTextStyle: TextStyle(color: colorScheme.onPrimary),
        actionTextColor: colorScheme.onPrimary,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      );

  static ThemeData dark(Color seedColor, {bool monochrome = false}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
      dynamicSchemeVariant: monochrome
          ? DynamicSchemeVariant.monochrome
          : DynamicSchemeVariant.tonalSpot,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      snackBarTheme: _snackBarTheme(colorScheme),
    );
  }

  static ThemeData light(Color seedColor, {bool monochrome = false}) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
      dynamicSchemeVariant: monochrome
          ? DynamicSchemeVariant.monochrome
          : DynamicSchemeVariant.tonalSpot,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      snackBarTheme: _snackBarTheme(colorScheme),
    );
  }
}
