import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/playback_error_event.dart';
import '../../../services/service_providers.dart';

export '../../../services/service_providers.dart' show playbackRepositoryProvider;

final playbackStateProvider = StreamProvider<PlaybackState>((ref) {
  return ref.watch(audioHandlerProvider).playbackState;
});

final currentMediaItemProvider = StreamProvider<MediaItem?>((ref) {
  return ref.watch(audioHandlerProvider).mediaItem;
});

/// The track id of whatever is currently loaded in the player (playing or
/// paused), so list tiles can highlight the matching row. Null when nothing
/// is loaded.
final currentTrackIdProvider = Provider<String?>((ref) {
  final mediaItem = ref.watch(currentMediaItemProvider).value;
  return mediaItem?.extras?['trackId'] as String?;
});

/// Whether the player is actively playing (not just loaded/paused) — used to
/// decide whether the now-playing indicator in list tiles should animate.
final isPlayingProvider = Provider<bool>((ref) {
  return ref.watch(playbackStateProvider).value?.playing ?? false;
});

final currentQueueProvider = StreamProvider<List<MediaItem>>((ref) {
  return ref.watch(audioHandlerProvider).queue;
});

final playbackErrorsProvider = StreamProvider<PlaybackErrorEvent>((ref) {
  return ref.watch(audioHandlerProvider).playbackErrors;
});

/// Windows-only: there's no hardware volume control on desktop, so the app
/// exposes its own. See [NowPlayingScreen]'s volume slider.
final volumeProvider = StreamProvider<double>((ref) {
  return ref.watch(audioHandlerProvider).volumeStream;
});

final positionDataProvider = StreamProvider<PositionData>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return AudioService.position.map((position) {
    final duration = handler.mediaItem.valueOrNull?.duration ?? Duration.zero;
    final bufferedPosition = handler.playbackState.valueOrNull?.bufferedPosition ??
        Duration.zero;
    return PositionData(position, bufferedPosition, duration);
  });
});

final isTrackCachedOnlyProvider = FutureProvider.family<bool, String>((
  ref,
  trackId,
) async {
  final downloaded = await ref.watch(trackRepositoryProvider).getDownloadedTrack(trackId);
  if (downloaded != null) return false;
  final cachedPath = await ref.watch(cacheServiceProvider).getCachedFilePath(trackId);
  return cachedPath != null;
});

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  const PositionData(this.position, this.bufferedPosition, this.duration);
}
