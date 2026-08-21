import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/duration_format.dart';
import '../../services/service_providers.dart';
import 'providers/player_providers.dart';
import 'queue_sheet.dart';

class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaItem = ref.watch(currentMediaItemProvider).value;
    final playbackState = ref.watch(playbackStateProvider).value;
    final positionData =
        ref.watch(positionDataProvider).value ??
        PositionData(Duration.zero, Duration.zero, Duration.zero);
    final handler = ref.watch(audioHandlerProvider);
    final playbackRepo = ref.watch(playbackRepositoryProvider);
    final trackId = mediaItem?.extras?['trackId'] as String?;
    final cachedOnly = trackId == null
        ? false
        : ref.watch(isTrackCachedOnlyProvider(trackId)).value ?? false;

    if (mediaItem == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Nothing playing')),
      );
    }

    final playing = playbackState?.playing ?? false;
    final shuffleEnabled =
        playbackState?.shuffleMode == AudioServiceShuffleMode.all;
    final repeatMode = playbackState?.repeatMode ?? AudioServiceRepeatMode.none;
    final maxMs = positionData.duration.inMilliseconds > 0
        ? positionData.duration.inMilliseconds.toDouble()
        : 1.0;
    final positionMs = positionData.position.inMilliseconds
        .toDouble()
        .clamp(0.0, maxMs);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing'),
        actions: [
          if (cachedOnly)
            IconButton(
              icon: const Icon(Icons.download_outlined),
              tooltip: 'Save to Downloads',
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                await ref.read(cacheServiceProvider).promoteToDownload(trackId);
                ref.invalidate(isTrackCachedOnlyProvider(trackId));
                messenger.showSnackBar(
                  const SnackBar(content: Text('Saved to Downloads')),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.queue_music),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => const QueueSheet(),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: mediaItem.artUri != null
                          ? CachedNetworkImage(
                              imageUrl: mediaItem.artUri.toString(),
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              child: const Icon(Icons.music_note, size: 96),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                mediaItem.title,
                style: Theme.of(context).textTheme.titleLarge,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              if (mediaItem.artist != null) ...[
                const SizedBox(height: 4),
                Text(
                  mediaItem.artist!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 16),
              Slider(
                min: 0,
                max: maxMs,
                value: positionMs,
                onChanged: (value) =>
                    handler.seek(Duration(milliseconds: value.round())),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(formatDuration(positionData.position)),
                    Text(formatDuration(positionData.duration)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.shuffle,
                      color: shuffleEnabled
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    onPressed: playbackRepo.toggleShuffle,
                  ),
                  IconButton(
                    iconSize: 36,
                    icon: const Icon(Icons.skip_previous),
                    onPressed: handler.skipToPrevious,
                  ),
                  IconButton(
                    iconSize: 56,
                    icon: Icon(
                      playing
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                    ),
                    onPressed: playing ? handler.pause : handler.play,
                  ),
                  IconButton(
                    iconSize: 36,
                    icon: const Icon(Icons.skip_next),
                    onPressed: handler.skipToNext,
                  ),
                  IconButton(
                    icon: Icon(
                      repeatMode == AudioServiceRepeatMode.one
                          ? Icons.repeat_one
                          : Icons.repeat,
                      color: repeatMode != AudioServiceRepeatMode.none
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    onPressed: playbackRepo.cycleRepeatMode,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
