class AppConstants {
  AppConstants._();

  static const String suggestEndpoint =
      'https://suggestqueries.google.com/complete/search';

  static const String downloadSubdirName = 'audio';

  static const String cacheSubdirName = 'cache_audio';

  static const Duration suggestionsDebounce = Duration(milliseconds: 300);

  static const List<Duration> sleepTimerPresets = [
    Duration(minutes: 15),
    Duration(minutes: 30),
    Duration(minutes: 45),
    Duration(minutes: 60),
    Duration(minutes: 90),
  ];
}
