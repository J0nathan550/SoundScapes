import 'package:flutter/material.dart';

enum AppThemePreset {
  violet,
  monochrome,
  blue,
  teal,
  green,
  orange,
  red,
  pink,
  custom;

  String get label => switch (this) {
    AppThemePreset.violet => 'Violet',
    AppThemePreset.monochrome => 'Black & White',
    AppThemePreset.blue => 'Blue',
    AppThemePreset.teal => 'Teal',
    AppThemePreset.green => 'Green',
    AppThemePreset.orange => 'Orange',
    AppThemePreset.red => 'Red',
    AppThemePreset.pink => 'Pink',
    AppThemePreset.custom => 'Custom',
  };

  Color? get seedColor => switch (this) {
    AppThemePreset.violet => const Color(0xFF7C4DFF),
    AppThemePreset.monochrome => const Color(0xFF000000),
    AppThemePreset.blue => const Color(0xFF2196F3),
    AppThemePreset.teal => const Color(0xFF009688),
    AppThemePreset.green => const Color(0xFF4CAF50),
    AppThemePreset.orange => const Color(0xFFFF9800),
    AppThemePreset.red => const Color(0xFFF44336),
    AppThemePreset.pink => const Color(0xFFE91E63),
    AppThemePreset.custom => null,
  };
}
