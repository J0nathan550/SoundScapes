enum DownloadStatus { queued, downloading, complete, failed }

class DownloadTask {
  final String trackId;
  final String title;
  final DownloadStatus status;
  final double? progressPercent;
  final String? errorMessage;
  final String? rawErrorMessage;

  const DownloadTask({
    required this.trackId,
    required this.title,
    required this.status,
    this.progressPercent,
    this.errorMessage,
    this.rawErrorMessage,
  });

  DownloadTask copyWith({
    DownloadStatus? status,
    double? progressPercent,
    String? errorMessage,
    String? rawErrorMessage,
  }) {
    return DownloadTask(
      trackId: trackId,
      title: title,
      status: status ?? this.status,
      progressPercent: progressPercent ?? this.progressPercent,
      errorMessage: errorMessage ?? this.errorMessage,
      rawErrorMessage: rawErrorMessage ?? this.rawErrorMessage,
    );
  }
}
