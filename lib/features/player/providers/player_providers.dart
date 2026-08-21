import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/service_providers.dart';

export '../../../services/service_providers.dart' show playbackRepositoryProvider;

final playbackStateProvider = StreamProvider<PlaybackState>((ref) {
  return ref.watch(audioHandlerProvider).playbackState;
});

final currentMediaItemProvider = StreamProvider<MediaItem?>((ref) {
  return ref.watch(audioHandlerProvider).mediaItem;
});

final currentQueueProvider = StreamProvider<List<MediaItem>>((ref) {
  return ref.watch(audioHandlerProvider).queue;
});

final playbackErrorsProvider = StreamProvider<String>((ref) {
  return ref.watch(audioHandlerProvider).playbackErrors;
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
