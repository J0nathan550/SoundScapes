import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/track.dart';
import '../../library/widgets/track_list_tile.dart';
import '../../player/providers/player_providers.dart';
import 'track_actions_row.dart';

class SearchResultTile extends ConsumerWidget {
  final Track track;

  const SearchResultTile({super.key, required this.track});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TrackListTile(
      track: track,
      onTap: () => ref.read(playbackRepositoryProvider).playSingleTrack(track),
      trailing: TrackActionsRow(track: track),
    );
  }
}
