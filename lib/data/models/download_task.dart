enum DownloadStatus { queued, downloading, complete, failed }

class DownloadTask {
  final String trackId;
  final String title;
  final DownloadStatus status;
  final double? progressPercent;
  final String? errorMessage;

  const DownloadTask({
    required this.trackId,
    required this.title,
    required this.status,
    this.progressPercent,
    this.errorMessage,
  });

  DownloadTask copyWith({
    DownloadStatus? status,
    double? progressPercent,
    String? errorMessage,
  }) {
    return DownloadTask(
      trackId: trackId,
      title: title,
      status: status ?? this.status,
      progressPercent: progressPercent ?? this.progressPercent,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
