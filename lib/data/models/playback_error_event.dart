/// A playback failure, carrying both the short user-facing message and the
/// original technical detail (shown instead when Developer mode is on).
class PlaybackErrorEvent {
  final String friendly;
  final String raw;

  const PlaybackErrorEvent({required this.friendly, required this.raw});
}
