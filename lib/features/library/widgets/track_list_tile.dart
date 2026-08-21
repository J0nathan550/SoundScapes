import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/duration_format.dart';
import '../../../data/models/track.dart';
import '../../../services/service_providers.dart';

class TrackListTile extends ConsumerWidget {
  final Track track;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool selected;
  final Widget? leadingOverlay;

  const TrackListTile({
    super.key,
    required this.track,
    this.onTap,
    this.trailing,
    this.selected = false,
    this.leadingOverlay,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preparing = ref.watch(preparingTrackIdProvider) == track.id;

    return ListTile(
      selected: selected,
      leading: SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CachedNetworkImage(
                imageUrl: track.thumbnailUrl,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                errorWidget: (_, _, _) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.music_note),
                ),
              ),
            ),
            if (preparing)
              Container(
                color: Colors.black45,
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              ),
            ?leadingOverlay,
          ],
        ),
      ),
      title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        preparing
            ? 'Preparing…'
            : '${track.author} · ${formatDuration(track.duration)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
