class ChannelResult {
  final String id;
  final String name;
  final String description;

  /// Null when YouTube didn't report a genuine video count for this result
  /// (some channel cards show a subscriber count in that slot instead).
  final int? videoCount;
  final String thumbnailUrl;

  const ChannelResult({
    required this.id,
    required this.name,
    required this.description,
    required this.videoCount,
    required this.thumbnailUrl,
  });
}

class PlaylistResult {
  final String id;
  final String title;
  final int videoCount;
  final String thumbnailUrl;

  const PlaylistResult({
    required this.id,
    required this.title,
    required this.videoCount,
    required this.thumbnailUrl,
  });
}
