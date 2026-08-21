import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const _snackBarTheme = SnackBarThemeData(
    backgroundColor: Colors.black,
    contentTextStyle: TextStyle(color: Colors.white),
    actionTextColor: Colors.white,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
    ),
  );

  static ThemeData dark(Color seedColor, {bool monochrome = false}) => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
      dynamicSchemeVariant: monochrome
          ? DynamicSchemeVariant.monochrome
          : DynamicSchemeVariant.tonalSpot,
    ),
    snackBarTheme: _snackBarTheme,
  );

  static ThemeData light(Color seedColor, {bool monochrome = false}) => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
      dynamicSchemeVariant: monochrome
          ? DynamicSchemeVariant.monochrome
          : DynamicSchemeVariant.tonalSpot,
    ),
    snackBarTheme: _snackBarTheme,
  );
}
