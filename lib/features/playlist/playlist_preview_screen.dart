import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/app_snackbar.dart';
import '../../data/models/track.dart';
import '../../services/service_providers.dart';
import '../library/widgets/track_list_tile.dart';
import '../search/widgets/track_actions_row.dart';
import 'providers/playlist_providers.dart';

class PlaylistPreviewScreen extends ConsumerWidget {
  final String playlistId;
  final String fallbackTitle;

  const PlaylistPreviewScreen({
    super.key,
    required this.playlistId,
    required this.fallbackTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(playlistTracksProvider(playlistId));

    return Scaffold(
      appBar: AppBar(
        title: Text(fallbackTitle),
        actions: [
          if (tracksAsync.value case final tracks? when tracks.isNotEmpty)
            _SaveAsFolderButton(title: fallbackTitle, tracks: tracks),
        ],
      ),
      body: tracksAsync.when(
        data: (tracks) {
          if (tracks.isEmpty) {
            return const Center(child: Text('This playlist has no videos.'));
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
                child: ListView.builder(
                  itemCount: tracks.length,
                  itemBuilder: (context, index) {
                    final track = tracks[index];
                    return TrackListTile(
                      track: track,
                      onTap: () => ref
                          .read(playbackRepositoryProvider)
                          .playTracks(tracks, startIndex: index),
                      trailing: TrackActionsRow(track: track),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load playlist: $e')),
      ),
    );
  }
}

class _SaveAsFolderButton extends ConsumerStatefulWidget {
  final String title;
  final List<Track> tracks;

  const _SaveAsFolderButton({required this.title, required this.tracks});

  @override
  ConsumerState<_SaveAsFolderButton> createState() => _SaveAsFolderButtonState();
}

class _SaveAsFolderButtonState extends ConsumerState<_SaveAsFolderButton> {
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    final repo = ref.read(folderRepositoryProvider);
    final folderId = await repo.createFolder(widget.title);
    for (final track in widget.tracks) {
      await repo.addTrackToFolder(folderId, track);
    }

    if (!mounted) return;
    setState(() => _saving = false);
    showAppSnackBar(
      messenger,
      'Saved "${widget.title}" as a folder',
      bottomInset: bottomInset,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_saving) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return IconButton(
      tooltip: 'Save as folder',
      icon: const Icon(Icons.playlist_add),
      onPressed: _save,
    );
  }
}
