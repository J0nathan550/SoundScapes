import 'dart:io';

import '../../data/db/app_database.dart';
import '../../data/models/track.dart';

class TrackRepository {
  final AppDatabase _db;

  TrackRepository(this._db);

  Stream<List<Track>> watchDownloadedTracks() => _db.watchDownloadedTracks();

  Future<void> upsertTrack(Track track) => _db.upsertTrack(track);

  Future<Track?> getDownloadedTrack(String trackId) =>
      _db.getDownloadedTrack(trackId);

  Future<List<Track>> getTracksByIds(List<String> ids) =>
      _db.getTracksByIds(ids);

  Future<void> recordDownload({
    required String trackId,
    required String filePath,
    required String container,
    required int fileSizeBytes,
  }) {
    return _db.insertDownloadedTrack(
      trackId: trackId,
      filePath: filePath,
      container: container,
      fileSizeBytes: fileSizeBytes,
    );
  }

  Future<void> deleteDownload(String trackId) async {
    final track = await _db.getDownloadedTrack(trackId);
    await _db.deleteDownloadedTrack(trackId);
    final path = track?.localFilePath;
    if (path == null) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Stream<int> watchTotalDownloadedBytes() => _db.watchTotalDownloadedBytes();

  Future<void> deleteAllDownloads() async {
    final paths = await _db.getAllDownloadedFilePaths();
    await _db.deleteAllDownloadedTracks();
    for (final path in paths) {
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (_) {
        // Best-effort: one locked/missing file shouldn't block the rest.
      }
    }
  }
}
