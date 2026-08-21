class PlaybackSnapshot {
  final String trackId;
  final int positionMs;

  const PlaybackSnapshot({required this.trackId, required this.positionMs});

  Map<String, dynamic> toJson() => {'trackId': trackId, 'positionMs': positionMs};

  static PlaybackSnapshot? fromJson(Map<String, dynamic> json) {
    final trackId = json['trackId'];
    final positionMs = json['positionMs'];
    if (trackId is! String || positionMs is! int) return null;
    return PlaybackSnapshot(trackId: trackId, positionMs: positionMs);
  }
}
