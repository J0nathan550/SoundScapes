import 'dart:async';

import '../settings/settings_service.dart';
import '../youtube/youtube_search_service.dart';
import 'audio_player_handler.dart';
import 'playback_repository.dart';

class AutoplayController {
  final AudioPlayerHandler _handler;
  final YoutubeSearchService _search;
  final PlaybackRepository _playback;
  final SettingsService _settings;
  final Set<String> _playedIds = {};
  StreamSubscription? _mediaItemSub;
  StreamSubscription? _completionSub;

  AutoplayController(
    this._handler,
    this._search,
    this._playback,
    this._settings,
  ) {
    _mediaItemSub = _handler.mediaItem.listen((item) {
      final id = item?.extras?['trackId'] as String?;
      if (id != null) _playedIds.add(id);
    });
    _completionSub = _handler.queueCompleted.listen((_) => _onQueueCompleted());
  }

  Future<void> _onQueueCompleted() async {
    if (!_settings.autoplayEnabled) return;
    final seed = _handler.mediaItem.valueOrNull;
    if (seed == null) return;
    try {
      final query = '${seed.artist ?? ''} ${seed.title}'.trim();
      final results = await _search.search(query);
      final fresh = results
          .where((t) => !_playedIds.contains(t.id))
          .take(3)
          .toList();
      if (fresh.isEmpty) return;
      await _playback.enqueueAndContinue(fresh);
    } catch (_) {}
  }

  void dispose() {
    _mediaItemSub?.cancel();
    _completionSub?.cancel();
  }
}
