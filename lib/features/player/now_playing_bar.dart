import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/service_providers.dart';
import 'now_playing_screen.dart';
import 'providers/player_providers.dart';

class NowPlayingBar extends ConsumerWidget {
  const NowPlayingBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaItem = ref.watch(currentMediaItemProvider).value;
    if (mediaItem == null) return const SizedBox.shrink();

    final playing = ref.watch(playbackStateProvider).value?.playing ?? false;
    final handler = ref.read(audioHandlerProvider);
    final positionData = ref.watch(positionDataProvider).value;
    final progress = (positionData != null && positionData.duration > Duration.zero)
        ? (positionData.position.inMilliseconds / positionData.duration.inMilliseconds)
              .clamp(0.0, 1.0)
        : 0.0;

    return Material(
      elevation: 8,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const NowPlayingScreen(),
            fullscreenDialog: true,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 64,
              child: Row(
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: mediaItem.artUri != null
                            ? CachedNetworkImage(
                                imageUrl: mediaItem.artUri.toString(),
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                child: const Icon(Icons.music_note),
                              ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mediaItem.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (mediaItem.artist != null)
                          Text(
                            mediaItem.artist!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_previous),
                    onPressed: handler.skipToPrevious,
                  ),
                  IconButton(
                    icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                    onPressed: playing ? handler.pause : handler.play,
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    onPressed: handler.skipToNext,
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
            IgnorePointer(
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
