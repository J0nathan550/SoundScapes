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
    return MaterialApp(
      title: 'SoundScapes',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(seedColor, monochrome: monochrome),
      darkTheme: AppTheme.dark(seedColor, monochrome: monochrome),
      themeMode: themeMode,
      home: const AppShell(),
    );
  }
}
