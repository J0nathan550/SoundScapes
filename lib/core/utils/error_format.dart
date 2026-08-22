/// A user-facing error message paired with the original technical detail.
/// [friendly] is shown by default; [raw] is shown instead when Developer
/// mode is enabled in Settings.
class FriendlyError {
  final String friendly;
  final String raw;

  const FriendlyError(this.friendly, this.raw);
}

/// Turns a download/playback exception (often a raw yt-dlp stderr dump or a
/// [PlatformException] wrapping one) into a short, plain-English message.
FriendlyError friendlyErrorFrom(Object error) {
  final raw = error.toString();
  final lower = raw.toLowerCase();

  final String friendly;
  if (lower.contains('429') || lower.contains('too many requests')) {
    friendly = 'YouTube is rate-limiting downloads right now. Try again in a bit.';
  } else if (lower.contains('403') || lower.contains('forbidden')) {
    friendly = 'YouTube blocked this request. Signing in from Settings can help.';
  } else if (lower.contains('sign in') || lower.contains('age-restricted')) {
    friendly = 'This video needs sign-in to play. Try signing in from Settings.';
  } else if (lower.contains('unavailable') || lower.contains('private video') ||
      lower.contains('no_output')) {
    friendly = 'This track isn\'t available anymore.';
  } else if (lower.contains('socketexception') ||
      lower.contains('failed host lookup') ||
      lower.contains('network is unreachable') ||
      lower.contains('connection')) {
    friendly = 'No internet connection.';
  } else {
    friendly = 'Something went wrong. Please try again.';
  }
  return FriendlyError(friendly, raw);
}
