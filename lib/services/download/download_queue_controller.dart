import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/constants.dart';
import '../../data/models/download_task.dart';
import '../../data/models/track.dart';
import '../service_providers.dart';

class DownloadQueueController extends Notifier<Map<String, DownloadTask>> {
  @override
  Map<String, DownloadTask> build() => {};

  Future<void> download(Track track) async {
    if (state[track.id]?.status == DownloadStatus.downloading) return;

    state = {
      ...state,
      track.id: DownloadTask(
        trackId: track.id,
        title: track.title,
        status: DownloadStatus.downloading,
      ),
    };

    final ytDlp = ref.read(ytDlpServiceProvider);
    final trackRepository = ref.read(trackRepositoryProvider);

    try {
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
      state = {
        ...state,
        track.id: (state[track.id] ??
                DownloadTask(
                  trackId: track.id,
                  title: track.title,
                  status: DownloadStatus.queued,
                ))
            .copyWith(status: DownloadStatus.failed, errorMessage: e.toString()),
      };
    }
  }

  Future<void> downloadAll(List<Track> tracks) async {
    for (final track in tracks) {
      if (track.isDownloaded) continue;
      await download(track);
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
