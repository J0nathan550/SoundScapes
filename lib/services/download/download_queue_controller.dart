import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/constants.dart';
import '../../core/utils/error_format.dart';
import '../../data/models/download_batch_summary.dart';
import '../../data/models/download_task.dart';
import '../../data/models/track.dart';
import '../service_providers.dart';

class DownloadQueueController extends Notifier<Map<String, DownloadTask>> {
  /// Track ids downloaded together, for the aggregate progress notification
  /// and Downloads-tab summary. Reset to just the newly-requested id(s) once
  /// nothing from the previous batch is still queued/downloading, so a fresh
  /// "download this one song" click doesn't keep inflating a long-finished
  /// batch's counts; otherwise extended, so a multi-track "download all" (or
  /// several individual downloads kicked off in quick succession) reads as
  /// one batch.
  Set<String> _batchTrackIds = {};
  Set<String> get batchTrackIds => _batchTrackIds;

  void _extendBatch(Iterable<String> trackIds) {
    final anyActive = state.values.any(
      (t) => t.status == DownloadStatus.downloading || t.status == DownloadStatus.queued,
    );
    _batchTrackIds = anyActive ? {..._batchTrackIds, ...trackIds} : trackIds.toSet();
  }

  @override
  Map<String, DownloadTask> build() => {};

  Future<void> download(Track track, {bool joinBatch = true}) async {
    if (state[track.id]?.status == DownloadStatus.downloading) return;
    if (track.isDownloaded) return;
    if (joinBatch) _extendBatch([track.id]);

    state = {
      ...state,
      track.id: DownloadTask(
        trackId: track.id,
        title: track.title,
        status: DownloadStatus.downloading,
      ),
    };

    final trackRepository = ref.read(trackRepositoryProvider);
    final cacheService = ref.read(cacheServiceProvider);

    try {
      // A cache entry means this exact file was already fetched (e.g. from
      // playback) — promote it into Downloads locally instead of hitting the
      // network again.
      final cachedPath = await cacheService.getCachedFilePath(track.id);
      if (cachedPath != null) {
        await trackRepository.upsertTrack(track);
        await cacheService.promoteToDownload(track.id);
      } else {
        final ytDlp = ref.read(ytDlpServiceProvider);
        final supportDir = await getApplicationSupportDirectory();
        final downloadsDir = p.join(supportDir.path, AppConstants.downloadSubdirName);
        final result = await ytDlp.downloadAudio(
          videoId: track.id,
          outputPathNoExt: p.join(downloadsDir, track.id),
          onProgress: (percent) {
            final current = state[track.id];
            if (current == null) return;
            state = {...state, track.id: current.copyWith(progressPercent: percent)};
          },
        );

        await trackRepository.upsertTrack(track);
        await trackRepository.recordDownload(
          trackId: track.id,
          filePath: result.filePath,
          container: p.extension(result.filePath).replaceFirst('.', ''),
          fileSizeBytes: result.fileSizeBytes,
        );
      }

      state = {
        ...state,
        track.id: (state[track.id] ??
                DownloadTask(
                  trackId: track.id,
                  title: track.title,
                  status: DownloadStatus.queued,
                ))
            .copyWith(status: DownloadStatus.complete),
      };
    } catch (e) {
      final formatted = friendlyErrorFrom(e);
      state = {
        ...state,
        track.id: (state[track.id] ??
                DownloadTask(
                  trackId: track.id,
                  title: track.title,
                  status: DownloadStatus.queued,
                ))
            .copyWith(
              status: DownloadStatus.failed,
              errorMessage: formatted.friendly,
              rawErrorMessage: formatted.raw,
            ),
      };
    }
  }

  Future<void> downloadAll(List<Track> tracks) async {
    final pending = tracks.where((t) => !t.isDownloaded).toList();
    if (pending.isEmpty) return;
    _extendBatch(pending.map((t) => t.id));
    for (final track in pending) {
      await download(track, joinBatch: false);
    }
  }

  void dismiss(String trackId) {
    final next = {...state}..remove(trackId);
    state = next;
  }
}

final downloadQueueControllerProvider =
    NotifierProvider<DownloadQueueController, Map<String, DownloadTask>>(
  DownloadQueueController.new,
);

/// Aggregate progress for the current download batch — see
/// [DownloadQueueController.batchTrackIds]. Drives the download notification
/// (via a listener in the app shell), the Downloads tab summary, and the nav
/// bar badge.
final downloadBatchSummaryProvider = Provider<DownloadBatchSummary>((ref) {
  final tasks = ref.watch(downloadQueueControllerProvider);
  final batchIds = ref.watch(downloadQueueControllerProvider.notifier).batchTrackIds;
  return DownloadBatchSummary.of(tasks, batchIds);
});
