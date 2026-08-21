import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

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
  );
}
