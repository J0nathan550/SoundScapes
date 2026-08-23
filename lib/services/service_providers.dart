import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../core/theme/theme_presets.dart';
import '../data/db/app_database.dart';
import 'auth/youtube_auth_service.dart';
import 'backup/backup_service.dart';
import 'download/cache_service.dart';
import 'download/download_notification_service.dart';
import 'download/ytdlp_service.dart';
import 'library/folder_repository.dart';
import 'library/track_repository.dart';
import 'playback/audio_player_handler.dart';
import 'playback/autoplay_controller.dart';
import 'playback/playback_persistence_controller.dart';
import 'playback/playback_repository.dart';
import 'settings/settings_service.dart';
import 'update/apk_installer.dart';
import 'update/update_service.dart';
import 'update/windows_update_installer.dart';
import 'window/window_theme_service.dart';
import 'youtube/authenticated_youtube_http_client.dart';
import 'youtube/youtube_search_service.dart';

final audioHandlerProvider = Provider<AudioPlayerHandler>((ref) {
  throw UnimplementedError('audioHandlerProvider must be overridden in main()');
});

final settingsServiceProvider = Provider<SettingsService>((ref) {
  throw UnimplementedError('settingsServiceProvider must be overridden in main()');
});

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final backupServiceProvider = Provider<BackupService>((ref) {
  final service = BackupService(
    ref.watch(settingsServiceProvider),
    ref.watch(appDatabaseProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

class BackupFolderController extends Notifier<String?> {
  @override
  String? build() => ref.watch(settingsServiceProvider).backupFolderDisplayName;

  Future<bool> pick() async {
    final picked = await ref.read(backupServiceProvider).pickFolder();
    if (picked) {
      state = ref.read(settingsServiceProvider).backupFolderDisplayName;
    }
    return picked;
  }

  Future<void> clear() async {
    await ref.read(backupServiceProvider).clearFolder();
    state = null;
  }
}

final backupFolderProvider = NotifierProvider<BackupFolderController, String?>(
  BackupFolderController.new,
);

class AutoExportController extends Notifier<bool> {
  @override
  bool build() => ref.watch(settingsServiceProvider).autoExportEnabled;

  Future<void> setEnabled(bool value) async {
    state = value;
    await ref.read(backupServiceProvider).setAutoExportEnabled(value);
    if (value) ref.read(backupServiceProvider).scheduleAutoExport();
  }
}

final autoExportEnabledProvider = NotifierProvider<AutoExportController, bool>(
  AutoExportController.new,
);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.watch(settingsServiceProvider).themeMode;

  void setThemeMode(ThemeMode mode) {
    state = mode;
    ref.read(settingsServiceProvider).setThemeMode(mode);
    ref.read(backupServiceProvider).scheduleAutoExport();
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

class ThemePresetController extends Notifier<AppThemePreset> {
  @override
  AppThemePreset build() => ref.watch(settingsServiceProvider).themePreset;

  void setPreset(AppThemePreset preset) {
    state = preset;
    ref.read(settingsServiceProvider).setThemePreset(preset);
    ref.read(backupServiceProvider).scheduleAutoExport();
  }
}

final themePresetProvider = NotifierProvider<ThemePresetController, AppThemePreset>(
  ThemePresetController.new,
);

class CustomThemeColorController extends Notifier<Color> {
  @override
  Color build() => ref.watch(settingsServiceProvider).customThemeColor;

  void setColor(Color color) {
    state = color;
    ref.read(settingsServiceProvider).setCustomThemeColor(color);
    ref.read(backupServiceProvider).scheduleAutoExport();
  }
}

final customThemeColorProvider = NotifierProvider<CustomThemeColorController, Color>(
  CustomThemeColorController.new,
);

final effectiveSeedColorProvider = Provider<Color>((ref) {
  final preset = ref.watch(themePresetProvider);
  return preset.seedColor ?? ref.watch(customThemeColorProvider);
});

class AutoplaySettingController extends Notifier<bool> {
  @override
  bool build() => ref.watch(settingsServiceProvider).autoplayEnabled;

  void setEnabled(bool value) {
    state = value;
    ref.read(settingsServiceProvider).setAutoplayEnabled(value);
    ref.read(backupServiceProvider).scheduleAutoExport();
  }
}

final autoplayEnabledProvider = NotifierProvider<AutoplaySettingController, bool>(
  AutoplaySettingController.new,
);

class ResumePlaybackController extends Notifier<bool> {
  @override
  bool build() => ref.watch(settingsServiceProvider).resumePlaybackEnabled;

  void setEnabled(bool value) {
    state = value;
    ref.read(settingsServiceProvider).setResumePlaybackEnabled(value);
    ref.read(backupServiceProvider).scheduleAutoExport();
  }
}

final resumePlaybackEnabledProvider =
    NotifierProvider<ResumePlaybackController, bool>(
      ResumePlaybackController.new,
    );

/// Shows raw technical error text (yt-dlp/PlatformException dumps) instead of
/// the short friendly message, for downloads and playback errors. A local
/// device preference, deliberately not included in the backup/export payload.
class DevModeController extends Notifier<bool> {
  @override
  bool build() => ref.watch(settingsServiceProvider).devModeEnabled;

  void setEnabled(bool value) {
    state = value;
    ref.read(settingsServiceProvider).setDevModeEnabled(value);
  }
}

final devModeEnabledProvider = NotifierProvider<DevModeController, bool>(
  DevModeController.new,
);

final updateServiceProvider = Provider<UpdateService>((ref) => UpdateService());

final apkInstallerProvider = Provider<ApkInstaller>((ref) => ApkInstaller());

final windowsUpdateInstallerProvider =
    Provider<WindowsUpdateInstaller>((ref) => WindowsUpdateInstaller());

final windowThemeServiceProvider =
    Provider<WindowThemeService>((ref) => WindowThemeService());

final packageInfoProvider = FutureProvider<PackageInfo>((ref) {
  return PackageInfo.fromPlatform();
});

final youtubeAuthServiceProvider = Provider<YoutubeAuthService>((ref) {
  return YoutubeAuthService();
});

class YoutubeAuthCookieController extends AsyncNotifier<String?> {
  @override
  Future<String?> build() {
    return ref.watch(youtubeAuthServiceProvider).loadCookie();
  }

  Future<void> signIn(String cookie) async {
    await ref.read(youtubeAuthServiceProvider).saveCookie(cookie);
    state = AsyncData(cookie);
  }

  Future<void> signOut() async {
    await ref.read(youtubeAuthServiceProvider).signOut();
    state = const AsyncData(null);
  }
}

final youtubeAuthCookieProvider =
    AsyncNotifierProvider<YoutubeAuthCookieController, String?>(
      YoutubeAuthCookieController.new,
    );

final youtubeExplodeProvider = Provider<YoutubeExplode>((ref) {
  final cookie = ref.watch(youtubeAuthCookieProvider).value;
  final client = cookie == null
      ? YoutubeHttpClient()
      : AuthenticatedYoutubeHttpClient(cookie);
  final yt = YoutubeExplode(httpClient: client);
  ref.onDispose(yt.close);
  return yt;
});

final youtubeSearchServiceProvider = Provider<YoutubeSearchService>((ref) {
  return YoutubeSearchService(ref.watch(youtubeExplodeProvider));
});

final folderRepositoryProvider = Provider<FolderRepository>((ref) {
  return FolderRepository(ref.watch(appDatabaseProvider));
});

final trackRepositoryProvider = Provider<TrackRepository>((ref) {
  return TrackRepository(ref.watch(appDatabaseProvider));
});

final ytDlpServiceProvider = Provider<YtDlpService>((ref) => YtDlpService());

final downloadNotificationServiceProvider = Provider<DownloadNotificationService>(
  (ref) => DownloadNotificationService(),
);

final cacheServiceProvider = Provider<CacheService>((ref) {
  return CacheService(ref.watch(ytDlpServiceProvider), ref.watch(trackRepositoryProvider));
});

final cacheSizeBytesProvider = StreamProvider<int>((ref) async* {
  final service = ref.watch(cacheServiceProvider);
  yield await service.cacheSizeBytes();
  await for (final _ in service.changes) {
    yield await service.cacheSizeBytes();
  }
});

final downloadedSizeBytesProvider = StreamProvider<int>((ref) {
  return ref.watch(trackRepositoryProvider).watchTotalDownloadedBytes();
});

/// Track ids currently being fetched/cached before playback can start. A set
/// rather than a single id because `playTracks` prepares every track in the
/// list concurrently (to warm the queue), not just the one that was tapped —
/// a single nullable value would have each concurrent preparation overwrite
/// the last, losing track of which rows are actually still loading.
class PreparingTrackIdsController extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void setPreparing(String trackId, bool preparing) {
    final next = {...state};
    if (preparing) {
      next.add(trackId);
    } else {
      next.remove(trackId);
    }
    state = next;
  }
}

final preparingTrackIdsProvider =
    NotifierProvider<PreparingTrackIdsController, Set<String>>(
      PreparingTrackIdsController.new,
    );

final playbackRepositoryProvider = Provider<PlaybackRepository>((ref) {
  return PlaybackRepository(
    ref.watch(audioHandlerProvider),
    ref.watch(cacheServiceProvider),
    ref.watch(trackRepositoryProvider),
    onPreparingChanged: (id, preparing) =>
        ref.read(preparingTrackIdsProvider.notifier).setPreparing(id, preparing),
  );
});

final playbackPersistenceControllerProvider =
    Provider<PlaybackPersistenceController>((ref) {
      final controller = PlaybackPersistenceController(
        ref.watch(audioHandlerProvider),
        ref.watch(settingsServiceProvider),
      );
      ref.onDispose(controller.dispose);
      return controller;
    });

final autoplayControllerProvider = Provider<AutoplayController>((ref) {
  final controller = AutoplayController(
    ref.watch(audioHandlerProvider),
    ref.watch(youtubeSearchServiceProvider),
    ref.watch(playbackRepositoryProvider),
    ref.watch(settingsServiceProvider),
  );
  ref.onDispose(controller.dispose);
  return controller;
});
