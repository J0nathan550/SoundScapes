import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/confirm_dialog.dart';
import '../../data/models/download_task.dart';
import '../../data/models/folder.dart';
import '../../data/models/track.dart';
import '../../services/download/download_queue_controller.dart';
import '../../services/service_providers.dart';
import '../player/now_playing_bar.dart';
import 'providers/library_providers.dart';
import 'widgets/like_button.dart';
import 'widgets/track_list_tile.dart';

class FolderDetailScreen extends ConsumerWidget {
  final Folder folder;

  const FolderDetailScreen({super.key, required this.folder});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, String currentName) async {
    final navigator = Navigator.of(context);
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete folder?',
      message: 'This removes "$currentName" but keeps any downloaded tracks.',
      confirmLabel: 'Delete',
    );
    if (confirmed) {
      await ref.read(folderRepositoryProvider).deleteFolder(folder.id);
      navigator.pop();
    }
  }

  Future<String?> _promptRename(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Folder name'),
          onSubmitted: (value) => Navigator.of(ctx).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  Future<void> _renameFolder(BuildContext context, WidgetRef ref, String currentName) async {
    final name = await _promptRename(context, currentName);
    if (name == null) return;
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed == currentName) return;
    await ref.read(folderRepositoryProvider).renameFolder(folder.id, trimmed);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(folderTracksProvider(folder.id));
    // `folder` is a snapshot passed in by the caller, so re-derive the live
    // name from the folders stream (falling back to that snapshot for the
    // system "Liked Songs" folder, which watchFolders() excludes) — otherwise
    // the app bar title wouldn't reflect a rename made from this same screen.
    final folders = ref.watch(foldersProvider).value;
    var currentName = folder.name;
    if (folders != null) {
      for (final f in folders) {
        if (f.id == folder.id) {
          currentName = f.name;
          break;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(currentName),
        actions: [
          if (tracksAsync.value case final tracks? when tracks.isNotEmpty)
            _DownloadAllButton(tracks: tracks),
          if (!folder.isSystem) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Rename folder',
              onPressed: () => _renameFolder(context, ref, currentName),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete folder',
              onPressed: () => _confirmDelete(context, ref, currentName),
            ),
          ],
        ],
      ),
      bottomNavigationBar: const NowPlayingBar(applyBottomSafeArea: true),
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
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                  ),
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
                      confirmDismiss: (_) => showConfirmDialog(
                        context,
                        title: 'Remove from folder?',
                        message: 'Remove "${track.title}" from "${folder.name}"?',
                        confirmLabel: 'Remove',
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
