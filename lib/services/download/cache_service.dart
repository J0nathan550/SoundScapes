import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/constants.dart';
import '../../data/models/track.dart';
import '../library/track_repository.dart';
import 'ytdlp_service.dart';

class CacheService {
  final YtDlpService _ytDlp;
  final TrackRepository _trackRepository;
  final _changes = StreamController<void>.broadcast();

  CacheService(this._ytDlp, this._trackRepository);

  /// Fires whenever a track is cached or the cache is cleared, so listeners
  /// (like the cache-size display in Settings) can stay up to date without
  /// waiting for the app to restart.
  Stream<void> get changes => _changes.stream;

  Future<Directory> _cacheDir() async {
    final supportDir = await getApplicationSupportDirectory();
    final dir = Directory(p.join(supportDir.path, AppConstants.cacheSubdirName));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<String?> getCachedFilePath(String trackId) async {
    final dir = await _cacheDir();
    if (!await dir.exists()) return null;
    await for (final entity in dir.list()) {
      if (entity is File && p.basenameWithoutExtension(entity.path) == trackId) {
        return entity.path;
      }
    }
    return null;
  }

  Future<String> ensureCached(
    Track track, {
    void Function(double percent)? onProgress,
  }) async {
    final existing = await getCachedFilePath(track.id);
    if (existing != null) return existing;

    final dir = await _cacheDir();
    final outputPathNoExt = p.join(dir.path, track.id);
    final result = await _ytDlp.downloadAudio(
      videoId: track.id,
      outputPathNoExt: outputPathNoExt,
      onProgress: onProgress,
    );
    _changes.add(null);
    return result.filePath;
  }

  Future<int> cacheSizeBytes() async {
    final dir = await _cacheDir();
    if (!await dir.exists()) return 0;
    var total = 0;
    await for (final entity in dir.list()) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }

  Future<void> clearCache() async {
    final dir = await _cacheDir();
    if (!await dir.exists()) return;
    await for (final entity in dir.list()) {
      if (entity is File) await entity.delete();
    }
    _changes.add(null);
  }

  Future<void> promoteToDownload(String trackId) async {
    final cachedPath = await getCachedFilePath(trackId);
    if (cachedPath == null) return;

    final supportDir = await getApplicationSupportDirectory();
    final downloadsDir = Directory(
      p.join(supportDir.path, AppConstants.downloadSubdirName),
    );
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }
    final ext = p.extension(cachedPath);
    final destPath = p.join(downloadsDir.path, '$trackId$ext');

    final movedFile = await File(cachedPath).copy(destPath);
    await File(cachedPath).delete();

    await _trackRepository.recordDownload(
      trackId: trackId,
      filePath: movedFile.path,
      container: ext.replaceFirst('.', ''),
      fileSizeBytes: await movedFile.length(),
    );
    _changes.add(null);
  }
}
