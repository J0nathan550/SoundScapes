import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_shell.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_presets.dart';
import 'services/playback/audio_player_handler.dart';
import 'services/service_providers.dart';
import 'services/settings/settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final audioHandler = await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.j0nathan550.soundscapes.channel.audio',
      androidNotificationChannelName: 'Playback',
      androidNotificationIcon: 'drawable/ic_notification',
      androidNotificationOngoing: true,
    ),
  );

  final prefs = await SharedPreferences.getInstance();
  final settingsService = SettingsService(prefs);

  if (Platform.isWindows) {
    await audioHandler.setVolume(settingsService.windowsVolume);
  } 

  runApp(
    ProviderScope(
      overrides: [
        audioHandlerProvider.overrideWithValue(audioHandler),
        settingsServiceProvider.overrideWithValue(settingsService),
      ],
      child: const MainApp(),
    ),
  );
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final seedColor = ref.watch(effectiveSeedColorProvider);
    final monochrome =
        ref.watch(themePresetProvider) == AppThemePreset.monochrome ||
        isAchromaticColor(seedColor);
    final lightTheme = AppTheme.light(seedColor, monochrome: monochrome);
    final darkTheme = AppTheme.dark(seedColor, monochrome: monochrome);

    if (Platform.isWindows) {
      final isDark = themeMode == ThemeMode.dark ||
          (themeMode == ThemeMode.system &&
              MediaQuery.platformBrightnessOf(context) == Brightness.dark);
      final Color captionColor;
      final Color textColor;
      if (monochrome) {
        // Material's monochrome scheme deliberately makes primary the
        // opposite extreme of the background for in-app contrast (white in
        // dark mode, black in light mode) — the exact opposite of what a
        // "Black & White" theme's title bar should look like. Use the raw
        // seed color itself instead, so a black pick reads as black.
        captionColor = seedColor;
        textColor = ThemeData.estimateBrightnessForColor(seedColor) == Brightness.dark
            ? Colors.white
            : Colors.black;
      } else {
        final scheme = (isDark ? darkTheme : lightTheme).colorScheme;
        captionColor = scheme.primary;
        textColor = scheme.onPrimary;
      }
      unawaited(
        ref.read(windowThemeServiceProvider).setTitleBarTheme(
              caption: captionColor,
              text: textColor,
              darkMode: isDark,
            ),
      );
    }

    return MaterialApp(
      title: 'SoundScapes',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      home: const AppShell(),
    );
  }
}
