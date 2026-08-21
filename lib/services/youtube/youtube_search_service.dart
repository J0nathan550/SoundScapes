import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../data/models/search_result_item.dart';
import '../../data/models/track.dart';

class YoutubeSearchService {
  final YoutubeExplode _yt;

  YoutubeSearchService(this._yt);

  Track videoToTrack(Video video) {
    return Track(
      id: video.id.value,
      title: video.title,
      author: video.author,
      duration: video.duration ?? Duration.zero,
      thumbnailUrl: video.thumbnails.mediumResUrl,
    );
  }

  ChannelResult _toChannelResult(SearchChannel c) => ChannelResult(
    id: c.id.value,
    name: c.name,
    description: c.description,
    videoCount: c.videoCount < 0 ? null : c.videoCount,
    thumbnailUrl: _bestThumbnailUrl(c.thumbnails),
  );

  PlaylistResult _toPlaylistResult(SearchPlaylist p) => PlaylistResult(
    id: p.id.value,
    title: p.title,
    videoCount: p.videoCount,
    thumbnailUrl: _bestThumbnailUrl(p.thumbnails),
  );

  String _bestThumbnailUrl(List<Thumbnail> thumbnails) =>
      thumbnails.isEmpty ? '' : thumbnails.last.url.toString();

  Future<List<Track>> search(String query) async {
    final results = await _yt.search.search(query);
    return results.map(videoToTrack).toList();
  }

  Future<List<ChannelResult>> searchChannels(String query) async {
    final results = await _yt.search.searchContent(
      query,
      filter: TypeFilters.channel,
    );
    return results.whereType<SearchChannel>().map(_toChannelResult).toList();
  }

  Future<List<PlaylistResult>> searchPlaylists(String query) async {
    final results = await _yt.search.searchContent(
      query,
      filter: TypeFilters.playlist,
    );
    return results.whereType<SearchPlaylist>().map(_toPlaylistResult).toList();
  }

  Future<Channel> getChannel(String channelId) => _yt.channels.get(channelId);

  Future<ChannelUploadsList> getChannelUploadsPage(String channelId) =>
      _yt.channels.getUploadsFromPage(channelId);

  Stream<Video> getPlaylistVideos(String playlistId) =>
      _yt.playlists.getVideos(playlistId);

  Future<List<String>> suggestions(String partialQuery) async {
    if (partialQuery.trim().isEmpty) return [];
    try {
      return await _yt.search.getQuerySuggestions(partialQuery);
    } catch (_) {
      return [];
    }
  }
}
