import 'dart:async';

import '../../youtube_explode_dart.dart';
import '../extensions/helpers_extension.dart';
import '../reverse_engineering/pages/channel_upload_page.dart';
import '../reverse_engineering/pages/playlist_page.dart';

/// This list contains a channel uploads.
/// This behaves like a [List] but has the [SearchList.nextPage] to get the next batch of videos.
class ChannelUploadsList extends BasePagedList<Video> {
  final ChannelUploadPage? _page;
  final PlaylistPage? _playlistPage;
  final YoutubeHttpClient _httpClient;

  final String author;
  final ChannelId channel;

  /// Construct an instance of [SearchList]
  /// See [SearchList]
  ChannelUploadsList(
    super.base,
    this.author,
    this.channel,
    this._page,
    this._httpClient,
  ) : _playlistPage = null;

  ChannelUploadsList._fromPlaylistPage(
    super.base,
    this.author,
    this.channel,
    this._playlistPage,
    this._httpClient,
  ) : _page = null;

  /// Builds a [ChannelUploadsList] from the channel's implicit "uploads"
  /// playlist rather than its Videos tab.
  ///
  /// Auto-generated "Topic" channels (e.g. music delivered through a
  /// distributor like DistroKid) have no Videos tab for [ChannelUploadPage]
  /// to scrape — YouTube serves their Home tab instead, whose "Albums &
  /// Singles" shelf lists albums, not individual videos — so
  /// [ChannelClient.getUploadsFromPage] falls back to this when
  /// [ChannelUploadPage] fails. Every channel has an implicit uploads
  /// playlist (`UU` + the channel ID suffix) that this works for instead.
  factory ChannelUploadsList.fromPlaylistPage(
    PlaylistPage playlistPage,
    String author,
    ChannelId channel,
    YoutubeHttpClient httpClient,
  ) {
    return ChannelUploadsList._fromPlaylistPage(
      playlistPage.videos
          .map(
            (v) => Video(
              VideoId(v.id),
              v.title,
              author,
              channel,
              v.uploadDateRaw.toDateTime(),
              v.uploadDateRaw,
              null,
              v.description,
              v.duration,
              ThumbnailSet(v.id),
              null,
              Engagement(v.viewCount, null, null),
              false,
            ),
          )
          .toList(),
      author,
      channel,
      playlistPage,
      httpClient,
    );
  }

  /// Fetches the next batch of videos or returns null if there are no more
  /// results.
  @override
  Future<ChannelUploadsList?> nextPage() async {
    final playlistPage = _playlistPage;
    if (playlistPage != null) {
      final next = await playlistPage.nextPage(_httpClient);
      if (next == null) {
        return null;
      }
      return ChannelUploadsList.fromPlaylistPage(
        next,
        author,
        channel,
        _httpClient,
      );
    }

    final page = await _page!.nextPage(_httpClient);
    if (page == null) {
      return null;
    }
    return ChannelUploadsList(
      page.uploads
          .map(
            (e) => Video(
              e.videoId,
              e.videoTitle,
              author,
              channel,
              e.videoUploadDate.toDateTime(),
              e.videoUploadDate,
              null,
              '',
              e.videoDuration,
              ThumbnailSet(e.videoId.value),
              null,
              Engagement(e.videoViews, null, null),
              false,
            ),
          )
          .toList(),
      author,
      channel,
      page,
      _httpClient,
    );
  }
}
