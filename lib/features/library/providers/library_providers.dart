import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/download_task.dart';
import '../../../data/models/folder.dart';
import '../../../data/models/track.dart';
import '../../../services/download/download_queue_controller.dart';
import '../../../services/service_providers.dart';

final foldersProvider = StreamProvider<List<Folder>>((ref) {
  return ref.watch(folderRepositoryProvider).watchFolders();
});

final folderTracksProvider = StreamProvider.family<List<Track>, int>((
  ref,
  folderId,
) {
  return ref.watch(folderRepositoryProvider).watchFolderTracks(folderId);
});

final likedSongsFolderIdProvider = FutureProvider<int>((ref) {
  return ref.watch(folderRepositoryProvider).getOrCreateLikedSongsFolderId();
});

final isTrackLikedProvider = StreamProvider.autoDispose.family<bool, String>((
  ref,
  trackId,
) {
  return ref.watch(folderRepositoryProvider).watchIsLiked(trackId);
});

final downloadedTracksProvider = StreamProvider<List<Track>>((ref) {
  return ref.watch(trackRepositoryProvider).watchDownloadedTracks();
});

final activeDownloadsProvider = Provider<List<DownloadTask>>((ref) {
  final tasks = ref.watch(downloadQueueControllerProvider);
  return tasks.values.where((t) => t.status != DownloadStatus.complete).toList();
});
