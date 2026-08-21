import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/track.dart';
import '../../../services/service_providers.dart';

final playlistTracksProvider = FutureProvider.family<List<Track>, String>((
  ref,
  id,
) async {
  final service = ref.watch(youtubeSearchServiceProvider);
  final tracks = <Track>[];
  await for (final video in service.getPlaylistVideos(id)) {
    tracks.add(service.videoToTrack(video));
  }
  return tracks;
});
