import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/download_task.dart';
import '../../../data/models/track.dart';
import '../../../services/download/download_queue_controller.dart';
import '../../library/widgets/add_to_folder_sheet.dart';
import '../../library/widgets/like_button.dart';
import '../../library/widgets/track_list_tile.dart';
import '../../player/providers/player_providers.dart';

class SearchResultTile extends ConsumerWidget {
  final Track track;

  const SearchResultTile({super.key, required this.track});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task = ref.watch(
      downloadQueueControllerProvider.select((tasks) => tasks[track.id]),
    );

    return TrackListTile(
      track: track,
      onTap: () => ref.read(playbackRepositoryProvider).playSingleTrack(track),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LikeButton(track: track),
          IconButton(
            tooltip: 'Add to folder',
            icon: const Icon(Icons.playlist_add),
            onPressed: () => showAddToFolderSheet(context, track),
          ),
          _DownloadButton(track: track, task: task),
        ],
      ),
    );
  }
}

class _DownloadButton extends ConsumerWidget {
  final Track track;
  final DownloadTask? task;

  const _DownloadButton({required this.track, this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (task?.status == DownloadStatus.downloading) {
      return SizedBox(
        width: 40,
        height: 40,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            value: task?.progressPercent == null ? null : task!.progressPercent! / 100,
          ),
        ),
      );
    }
    if (task?.status == DownloadStatus.complete || track.isDownloaded) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: Icon(Icons.check_circle, color: Colors.green),
      );
    }
    return IconButton(
      tooltip: 'Download',
      icon: const Icon(Icons.download),
      onPressed: () =>
          ref.read(downloadQueueControllerProvider.notifier).download(track),
    );
  }
}
