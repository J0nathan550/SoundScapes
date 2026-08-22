import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/confirm_dialog.dart';
import '../../data/models/download_batch_summary.dart';
import '../../data/models/download_task.dart';
import '../../services/download/download_queue_controller.dart';
import '../../services/service_providers.dart';
import '../player/now_playing_bar.dart';
import 'providers/library_providers.dart';
import 'widgets/track_list_tile.dart';

class DownloadedScreen extends ConsumerWidget {
  const DownloadedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadedAsync = ref.watch(downloadedTracksProvider);
    final activeDownloads = ref.watch(activeDownloadsProvider);
    final batchSummary = ref.watch(downloadBatchSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Downloaded')),
      bottomNavigationBar: const NowPlayingBar(applyBottomSafeArea: true),
      body: ListView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        children: [
          if (!batchSummary.isEmpty) _BatchSummaryHeader(summary: batchSummary),
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
                        onPressed: () async {
                          final confirmed = await showConfirmDialog(
                            context,
                            title: 'Delete download?',
                            message:
                                'Delete "${tracks[i].title}" from your downloads? '
                                'You can re-download it later.',
                            confirmLabel: 'Delete',
                          );
                          if (!confirmed) return;
                          ref.read(trackRepositoryProvider).deleteDownload(tracks[i].id);
                        },
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

class _BatchSummaryHeader extends StatelessWidget {
  final DownloadBatchSummary summary;

  const _BatchSummaryHeader({required this.summary});

  @override
  Widget build(BuildContext context) {
    final segments = [
      if (summary.completed > 0) '${summary.completed} downloaded',
      if (summary.failed > 0) '${summary.failed} failed',
      if (summary.remaining > 0) '${summary.remaining} remaining',
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summary.isActive ? 'Downloading…' : 'Downloads finished',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 2),
          Text(segments.join(' · '), style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (summary.completed + summary.failed) / summary.total,
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
    final devMode = ref.watch(devModeEnabledProvider);
    final errorText = devMode ? task.rawErrorMessage : task.errorMessage;
    return ListTile(
      leading: Icon(
        isFailed ? Icons.error_outline : Icons.downloading,
        color: isFailed ? Theme.of(context).colorScheme.error : null,
      ),
      title: Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: isFailed
          ? Text(errorText ?? 'Download failed')
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
