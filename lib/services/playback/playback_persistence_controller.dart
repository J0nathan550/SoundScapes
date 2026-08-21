import 'dart:async';

import '../../data/models/playback_snapshot.dart';
import '../library/track_repository.dart';
import '../settings/settings_service.dart';
import 'audio_player_handler.dart';
import 'playback_repository.dart';

class PlaybackPersistenceController {
  final AudioPlayerHandler _handler;
  final SettingsService _settings;
  Timer? _ticker;
  StreamSubscription? _mediaItemSub;
  StreamSubscription? _playbackStateSub;

  PlaybackPersistenceController(this._handler, this._settings) {
    _mediaItemSub = _handler.mediaItem.listen((_) => _persist());
    _playbackStateSub = _handler.playbackState.listen((state) {
      if (!state.playing) _persist();
    });
    _ticker = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_handler.playbackState.valueOrNull?.playing ?? false) _persist();
    });
  }

  void _persist() {
    final item = _handler.mediaItem.valueOrNull;
    final trackId = item?.extras?['trackId'] as String?;
    if (trackId == null) return;
    final position =
        _handler.playbackState.valueOrNull?.updatePosition ?? Duration.zero;
    _settings.savePlaybackSnapshot(
      PlaybackSnapshot(trackId: trackId, positionMs: position.inMilliseconds),
    );
  }

  Future<void> restoreIfEnabled(
    PlaybackRepository playback,
    TrackRepository trackRepository,
  ) async {
    if (!_settings.resumePlaybackEnabled) return;
    final snapshot = _settings.playbackSnapshot;
    if (snapshot == null) return;
    final tracks = await trackRepository.getTracksByIds([snapshot.trackId]);
    if (tracks.isEmpty) return;
    await playback.restoreLastTrack(
      tracks.first,
      Duration(milliseconds: snapshot.positionMs),
    );
  }

  void dispose() {
    _ticker?.cancel();
    _mediaItemSub?.cancel();
    _playbackStateSub?.cancel();
  }
}
