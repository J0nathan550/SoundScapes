import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';

import '../../core/utils/error_format.dart';
import '../../data/models/playback_error_event.dart';
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
  final void Function(String trackId, bool preparing)? onPreparingChanged;

  /// Bumped by every call that starts a new playback context (a fresh tap,
  /// not extending the current queue). The background queue-filler in
  /// [playTracks] checks this before each step and bails out if a newer
  /// play request has superseded it, so rapidly tapping between tracks
  /// can't have a stale background fill corrupt the new queue.
  int _playEpoch = 0;

  PlaybackRepository(
    this._handler,
    this._cacheService,
    this._trackRepository, {
    this.onPreparingChanged,
  });

  Future<MediaItem> _toMediaItem(Track track, {bool reportPreparing = true}) async {
    await _trackRepository.upsertTrack(track);
    final String localPath;
    if (track.isDownloaded && track.localFilePath != null) {
      localPath = track.localFilePath!;
    } else {
      if (reportPreparing) onPreparingChanged?.call(track.id, true);
      try {
        localPath = await _cacheService.ensureCached(track);
      } finally {
        if (reportPreparing) onPreparingChanged?.call(track.id, false);
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
    _playEpoch++;
    try {
      final item = await _toMediaItem(track);
      await _handler.updateQueue([item]);
      await _handler.skipToQueueItem(0);
      await _handler.play();
    } catch (e) {
      _handler.reportError(_friendlyError(track, e));
    }
  }

  /// Plays [tracks] starting at [startIndex]. Only the tapped track is
  /// resolved up front so playback starts immediately — the rest of the
  /// list is then resolved one at a time in the background (not all
  /// concurrently) and quietly appended/prepended into the real queue as
  /// each one finishes, so skipping forward or back usually finds the next
  /// track already there without a burst of simultaneous fetches for
  /// tracks the user hasn't reached yet.
  Future<void> playTracks(List<Track> tracks, {int startIndex = 0}) async {
    if (tracks.isEmpty) return;
    final epoch = ++_playEpoch;
    try {
      final item = await _toMediaItem(tracks[startIndex]);
      if (epoch != _playEpoch) return;
      await _handler.updateQueue([item]);
      await _handler.skipToQueueItem(0);
      await _handler.play();
    } catch (e) {
      if (epoch == _playEpoch) _handler.reportError(_friendlyError(tracks[startIndex], e));
      return;
    }
    unawaited(_fillQueueInBackground(tracks, startIndex, epoch));
  }

  Future<void> _fillQueueInBackground(List<Track> tracks, int startIndex, int epoch) async {
    for (var i = startIndex + 1; i < tracks.length; i++) {
      if (epoch != _playEpoch) return;
      try {
        // reportPreparing: false — this is silent pre-fetching for tracks
        // the user hasn't reached yet, not the one they tapped. Reporting it
        // made every row's "preparing" spinner flash on as the background
        // fill silently walked through the whole list, one row at a time.
        final item = await _toMediaItem(tracks[i], reportPreparing: false);
        if (epoch != _playEpoch) return;
        await _handler.addQueueItem(item);
      } catch (_) {
        // A track that fails to prepare in the background is simply
        // skipped from the queue; the user only sees an error if they
        // actually try to play one directly.
      }
    }
    // Windows' just_audio backend (WinRT MediaPlaybackList) doesn't reliably
    // preserve which item is "current" when items are inserted before it —
    // in practice, inserting here while the tapped track is still playing
    // makes playback jump back to the very first item in the list.
    //
    // Linux (just_audio_media_kit -> media_kit, backed by libmpv) has its own
    // unrelated but equally real problem with the same operation: inserting
    // anywhere but the tail goes through just_audio_media_kit's
    // concatenatingInsertAll (mediakit_player.dart), which calls
    // Player.move(length, index) using the post-append playlist length as
    // the "from" index — one past the item's actual position (length - 1).
    // media_kit's own move() (native/player/real.dart) silently no-ops its
    // Dart-side queue bookkeeping for that out-of-range index (a
    // SplayTreeMap.remove miss) but still forwards the same out-of-range
    // `playlist-move` command to mpv regardless, desyncing Dart's view of
    // the queue from mpv's actual playback order — confirmed by reading
    // both packages' source directly, not just inferred from symptoms.
    //
    // Android handles this fine, so only skip it on Windows/Linux; "skip
    // previous" just won't have earlier tracks pre-loaded there.
    if (Platform.isWindows || Platform.isLinux) return;
    for (var i = startIndex - 1; i >= 0; i--) {
      if (epoch != _playEpoch) return;
      try {
        final item = await _toMediaItem(tracks[i], reportPreparing: false);
        if (epoch != _playEpoch) return;
        await _handler.insertQueueItemAt(0, item);
      } catch (_) {}
    }
  }

  Future<void> restoreLastTrack(Track track, Duration position) async {
    _playEpoch++;
    try {
      final item = await _toMediaItem(track);
      await _handler.updateQueue([item]);
      await _handler.skipToQueueItem(0);
      await _handler.seek(position);
    } catch (_) {}
  }

  /// Plays [tracks] in randomized order. Shuffling the list up front — rather
  /// than playing in original order and toggling shuffle mode afterward —
  /// avoids a race with [playTracks]'s background queue fill: that fill
  /// starts appending the remaining tracks in original order right away, so
  /// flipping shuffle mode after the fact only ever reshuffles the handful
  /// of items that happened to be queued by that point.
  Future<void> playTracksShuffled(List<Track> tracks) async {
    if (tracks.isEmpty) return;
    final shuffled = List<Track>.of(tracks)..shuffle();
    await playTracks(shuffled);
  }

  Future<void> enqueueAndContinue(List<Track> tracks) async {
    final items = await Future.wait(tracks.map(_toMediaItem));
    await _handler.addQueueItems(items);
    await _handler.play();
  }

  PlaybackErrorEvent _friendlyError(Track track, Object e) {
    final formatted = friendlyErrorFrom(e);
    return PlaybackErrorEvent(
      friendly: 'Couldn\'t play "${track.title}": ${formatted.friendly}',
      raw: 'Couldn\'t play "${track.title}": ${formatted.raw}',
    );
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
