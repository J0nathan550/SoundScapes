import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../data/models/search_result_item.dart';
import '../../playlist/playlist_preview_screen.dart';

class PlaylistResultTile extends StatelessWidget {
  final PlaylistResult playlist;

  const PlaylistResultTile({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SizedBox(
        width: 48,
        height: 48,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: playlist.thumbnailUrl.isEmpty
              ? Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.playlist_play),
                )
              : CachedNetworkImage(
                  imageUrl: playlist.thumbnailUrl,
                  fit: BoxFit.cover,
                  memCacheWidth: 96,
                  memCacheHeight: 96,
                  errorWidget: (_, _, _) => Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.playlist_play),
                  ),
                ),
        ),
      ),
      title: Text(playlist.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${playlist.videoCount} videos'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PlaylistPreviewScreen(
            playlistId: playlist.id,
            fallbackTitle: playlist.title,
          ),
        ),
      ),
    );
  }
}
