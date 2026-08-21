import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/download_task.dart';
import '../../services/download/download_queue_controller.dart';
import '../../services/service_providers.dart';
import 'providers/library_providers.dart';
import 'widgets/track_list_tile.dart';

class DownloadedScreen extends ConsumerWidget {
  const DownloadedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadedAsync = ref.watch(downloadedTracksProvider);
    final activeDownloads = ref.watch(activeDownloadsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Downloaded')),
      body: ListView(
        children: [
          if (activeDownloads.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                'In progress',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            for (final task in activeDownloads) _ActiveDownloadTile(task: task),
            const Divider(),
          ],
          downloadedAsync.when(
            data: (tracks) {
              if (tracks.isEmpty && activeDownloads.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No downloads yet.')),
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < tracks.length; i++)
                    TrackListTile(
                      track: tracks[i],
                      onTap: () => ref
                          .read(playbackRepositoryProvider)
                          .playTracks(tracks, startIndex: i),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => ref
                            .read(trackRepositoryProvider)
                            .deleteDownload(tracks[i].id),
                      ),
                    ),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Failed to load downloads: $e'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveDownloadTile extends ConsumerWidget {
  final DownloadTask task;

  const _ActiveDownloadTile({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFailed = task.status == DownloadStatus.failed;
    return ListTile(
      leading: Icon(
        isFailed ? Icons.error_outline : Icons.downloading,
        color: isFailed ? Theme.of(context).colorScheme.error : null,
      ),
      title: Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: isFailed
          ? Text(task.errorMessage ?? 'Download failed')
          : LinearProgressIndicator(
              value: task.progressPercent == null ? null : task.progressPercent! / 100,
            ),
      trailing: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => ref
            .read(downloadQueueControllerProvider.notifier)
            .dismiss(task.trackId),
      ),
    );
  }
}
