class AppConstants {
  AppConstants._();

  static const String suggestEndpoint =
      'https://suggestqueries.google.com/complete/search';

  static const String downloadSubdirName = 'audio';

  static const String cacheSubdirName = 'cache_audio';

  static const String updateDownloadSubdirName = 'updates';

  static const String githubOwner = 'J0nathan550';

  static const String githubRepo = 'SoundScapes';

  /// Name of the Windows release asset built by .github/workflows/release.yml
  /// — a zip of the portable Release build. Must match that workflow's
  /// `Compress-Archive` output name.
  static const String windowsReleaseAssetName = 'soundscapes-windows.zip';

  static const Duration suggestionsDebounce = Duration(milliseconds: 300);

  static const List<Duration> sleepTimerPresets = [
    Duration(minutes: 15),
    Duration(minutes: 30),
    Duration(minutes: 45),
    Duration(minutes: 60),
    Duration(minutes: 90),
  ];
}
