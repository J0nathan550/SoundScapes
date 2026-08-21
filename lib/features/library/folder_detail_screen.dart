import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/download_task.dart';
import '../../data/models/folder.dart';
import '../../data/models/track.dart';
import '../../services/download/download_queue_controller.dart';
import '../../services/service_providers.dart';
import 'providers/library_providers.dart';
import 'widgets/like_button.dart';
import 'widgets/track_list_tile.dart';

class FolderDetailScreen extends ConsumerWidget {
  final Folder folder;

  const FolderDetailScreen({super.key, required this.folder});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete folder?'),
        content: Text(
          'This removes "${folder.name}" but keeps any downloaded tracks.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(folderRepositoryProvider).deleteFolder(folder.id);
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(folderTracksProvider(folder.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(folder.name),
        actions: [
          if (tracksAsync.value case final tracks? when tracks.isNotEmpty)
            _DownloadAllButton(tracks: tracks),
          if (!folder.isSystem)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete folder',
              onPressed: () => _confirmDelete(context, ref),
            ),
        ],
      ),
      body: tracksAsync.when(
        data: (tracks) {
          if (tracks.isEmpty) {
            return const Center(
              child: Text('No tracks yet. Add some from Search.'),
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Play all'),
                        onPressed: () =>
                            ref.read(playbackRepositoryProvider).playTracks(tracks),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.shuffle),
                        label: const Text('Shuffle'),
                        onPressed: () async {
                          final repo = ref.read(playbackRepositoryProvider);
                          await repo.playTracks(tracks);
                          await repo.toggleShuffle();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ReorderableListView.builder(
                  itemCount: tracks.length,
                  itemBuilder: (context, index) {
                    final track = tracks[index];
                    return Dismissible(
                      key: ValueKey(track.id),
                      background: Container(
                        color: Colors.redAccent,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => ref
                          .read(folderRepositoryProvider)
                          .removeTrackFromFolder(folder.id, track.id),
                      child: TrackListTile(
                        track: track,
                        onTap: () => ref
                            .read(playbackRepositoryProvider)
                            .playTracks(tracks, startIndex: index),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LikeButton(track: track),
                            const Icon(Icons.drag_handle),
                          ],
                        ),
                      ),
                    );
                  },
                  onReorderItem: (oldIndex, newIndex) {
                    final reordered = [...tracks];
                    final moved = reordered.removeAt(oldIndex);
                    reordered.insert(newIndex, moved);
                    ref
                        .read(folderRepositoryProvider)
                        .reorderTracks(
                          folder.id,
                          reordered.map((t) => t.id).toList(),
                        );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load tracks: $e')),
      ),
    );
  }
}

class _DownloadAllButton extends ConsumerWidget {
  final List<Track> tracks;

  const _DownloadAllButton({required this.tracks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(downloadQueueControllerProvider);
    final trackIds = tracks.map((t) => t.id).toSet();
    final relevantTasks = tasks.values.where((t) => trackIds.contains(t.trackId));
    final anyDownloading = relevantTasks.any(
      (t) => t.status == DownloadStatus.downloading,
    );
    final allDownloaded = tracks.every((t) => t.isDownloaded);

    if (anyDownloading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (allDownloaded) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Icon(Icons.download_done, color: Colors.green),
      );
    }
    return IconButton(
      tooltip: 'Download all',
      icon: const Icon(Icons.download_for_offline_outlined),
      onPressed: () =>
          ref.read(downloadQueueControllerProvider.notifier).downloadAll(tracks),
    );
  }
}
