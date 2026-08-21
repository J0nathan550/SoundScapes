import 'package:audio_service/audio_service.dart';

import '../../data/models/track.dart';
import '../download/cache_service.dart';
import '../library/track_repository.dart';
import 'audio_player_handler.dart';

const _repeatModeCycle = [
  AudioServiceRepeatMode.none,
  AudioServiceRepeatMode.all,
  AudioServiceRepeatMode.one,
];

class PlaybackRepository {
  final AudioPlayerHandler _handler;
  final CacheService _cacheService;
  final TrackRepository _trackRepository;
  final void Function(String? trackId)? onPreparingChanged;

  PlaybackRepository(
    this._handler,
    this._cacheService,
    this._trackRepository, {
    this.onPreparingChanged,
  });

  Future<MediaItem> _toMediaItem(Track track) async {
    await _trackRepository.upsertTrack(track);
    final String localPath;
    if (track.isDownloaded && track.localFilePath != null) {
      localPath = track.localFilePath!;
    } else {
      onPreparingChanged?.call(track.id);
      try {
        localPath = await _cacheService.ensureCached(track);
      } finally {
        onPreparingChanged?.call(null);
      }
    }
    return MediaItem(
      id: Uri.file(localPath).toString(),
      title: track.title,
      artist: track.author,
      duration: track.duration,
      artUri: Uri.tryParse(track.thumbnailUrl),
      extras: {'trackId': track.id},
    );
  }

  Future<void> playSingleTrack(Track track) async {
    try {
      final item = await _toMediaItem(track);
      await _handler.updateQueue([item]);
      await _handler.skipToQueueItem(0);
      await _handler.play();
    } catch (e) {
      _handler.reportError(_friendlyError(track, e));
    }
  }

  Future<void> playTracks(List<Track> tracks, {int startIndex = 0}) async {
    if (tracks.isEmpty) return;
    try {
      final items = await Future.wait(tracks.map(_toMediaItem));
      await _handler.updateQueue(items);
      await _handler.skipToQueueItem(startIndex);
      await _handler.play();
    } catch (e) {
      _handler.reportError(_friendlyError(tracks[startIndex], e));
    }
  }

  Future<void> restoreLastTrack(Track track, Duration position) async {
    try {
      final item = await _toMediaItem(track);
      await _handler.updateQueue([item]);
      await _handler.skipToQueueItem(0);
      await _handler.seek(position);
    } catch (_) {}
  }

  Future<void> enqueueAndContinue(List<Track> tracks) async {
    final items = await Future.wait(tracks.map(_toMediaItem));
    await _handler.addQueueItems(items);
    await _handler.play();
  }

  String _friendlyError(Track track, Object e) {
    return 'Couldn\'t play "${track.title}": $e';
  }

  Future<void> toggleShuffle() async {
    final enabled =
        _handler.playbackState.value.shuffleMode == AudioServiceShuffleMode.all;
    await _handler.setShuffleMode(
      enabled ? AudioServiceShuffleMode.none : AudioServiceShuffleMode.all,
    );
  }

  Future<void> cycleRepeatMode() async {
    final current = _handler.playbackState.value.repeatMode;
    final next =
        _repeatModeCycle[(_repeatModeCycle.indexOf(current) + 1) % _repeatModeCycle.length];
    await _handler.setRepeatMode(next);
  }
}
