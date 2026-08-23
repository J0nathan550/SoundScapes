import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/service_providers.dart';
import 'providers/player_providers.dart';

class QueueSheet extends ConsumerWidget {
  const QueueSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(currentQueueProvider).value ?? const [];
    final currentIndex = ref.watch(playbackStateProvider).value?.queueIndex;
    final handler = ref.watch(audioHandlerProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Up next',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: queue.isEmpty
                  ? const Center(child: Text('Queue is empty'))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: queue.length,
                      itemBuilder: (context, index) {
                        final item = queue[index];
                        final isCurrent = index == currentIndex;
                        return ListTile(
                          selected: isCurrent,
                          leading: item.artUri != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: CachedNetworkImage(
                                    imageUrl: item.artUri.toString(),
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    memCacheWidth: 80,
                                    memCacheHeight: 80,
                                  ),
                                )
                              : const Icon(Icons.music_note),
                          title: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: item.artist != null
                              ? Text(
                                  item.artist!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                          onTap: () => handler.skipToQueueItem(index),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
