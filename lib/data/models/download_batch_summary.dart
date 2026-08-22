import 'download_task.dart';

/// Aggregate progress for the current batch of downloads (the tracks queued
/// or downloading together, plus how each one landed) — backs the download
/// notification, the Downloads tab summary, and the nav bar badge.
class DownloadBatchSummary {
  final int completed;
  final int failed;
  final int remaining;

  const DownloadBatchSummary({
    required this.completed,
    required this.failed,
    required this.remaining,
  });

  static const empty = DownloadBatchSummary(completed: 0, failed: 0, remaining: 0);

  int get total => completed + failed + remaining;
  bool get isEmpty => total == 0;
  bool get isActive => remaining > 0;

  static DownloadBatchSummary of(
    Map<String, DownloadTask> tasks,
    Set<String> batchTrackIds,
  ) {
    var completed = 0;
    var failed = 0;
    var remaining = 0;
    for (final id in batchTrackIds) {
      switch (tasks[id]?.status) {
        case DownloadStatus.complete:
          completed++;
        case DownloadStatus.failed:
          failed++;
        case DownloadStatus.queued:
        case DownloadStatus.downloading:
          remaining++;
        case null:
          break; // Dismissed from the queue — no longer part of the batch.
      }
    }
    return DownloadBatchSummary(completed: completed, failed: failed, remaining: remaining);
  }
}
