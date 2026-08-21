import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../data/models/track.dart';

class YoutubeSearchService {
  final YoutubeExplode _yt;

  YoutubeSearchService(this._yt);

  Track _toTrack(Video video) {
    return Track(
      id: video.id.value,
      title: video.title,
      author: video.author,
      duration: video.duration ?? Duration.zero,
      thumbnailUrl: video.thumbnails.mediumResUrl,
    );
  }

  Future<List<Track>> search(String query) async {
    final results = await _yt.search.search(query);
    return results.map(_toTrack).toList();
  }

  Future<List<String>> suggestions(String partialQuery) async {
    if (partialQuery.trim().isEmpty) return [];
    try {
      return await _yt.search.getQuerySuggestions(partialQuery);
    } catch (_) {
      return [];
    }
  }
}
