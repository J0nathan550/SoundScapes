class AppConstants {
  AppConstants._();

  static const String suggestEndpoint =
      'https://suggestqueries.google.com/complete/search';

  static const String downloadSubdirName = 'audio';

  static const String cacheSubdirName = 'cache_audio';

  static const Duration suggestionsDebounce = Duration(milliseconds: 300);
}
