import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/constants.dart';
import '../../data/models/update_info.dart';

/// Thrown by [UpdateService.downloadApk] when the caller's `isCancelled`
/// check returns true mid-download, so callers can distinguish a deliberate
/// cancel from a real failure.
class UpdateDownloadCancelled implements Exception {
  const UpdateDownloadCancelled();
}

class UpdateService {
  static final Uri _latestReleaseUri = Uri.parse(
    'https://api.github.com/repos/${AppConstants.githubOwner}/${AppConstants.githubRepo}/releases/latest',
  );

  /// Checks GitHub for the latest release and returns it only if it's newer
  /// than [currentVersion] (e.g. "1.0.42"). Returns null when already
  /// current, or when the release has no APK asset.
  Future<UpdateInfo?> fetchLatestIfNewer(String currentVersion) async {
    final response = await http.get(
      _latestReleaseUri,
      headers: const {'Accept': 'application/vnd.github+json'},
    );
    if (response.statusCode != 200) {
      throw Exception(
        'GitHub returned ${response.statusCode} while checking for updates',
      );
    }

    final body = json.decode(response.body) as Map<String, dynamic>;
    final tagName = body['tag_name'] as String? ?? '';
    final version = tagName.startsWith('v') ? tagName.substring(1) : tagName;
    final releaseUrl = body['html_url'] as String? ?? '';

    final assets = (body['assets'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final apkAsset = assets.cast<Map<String, dynamic>?>().firstWhere(
      (a) => (a?['name'] as String?)?.toLowerCase().endsWith('.apk') ?? false,
      orElse: () => null,
    );
    if (apkAsset == null) return null;

    if (!_isNewer(version, currentVersion)) return null;

    return UpdateInfo(
      version: version,
      apkDownloadUrl: apkAsset['browser_download_url'] as String,
      apkSizeBytes: (apkAsset['size'] as num?)?.toInt() ?? 0,
      releaseUrl: releaseUrl,
    );
  }

  bool _isNewer(String latest, String current) {
    final latestParts = _versionParts(latest);
    final currentParts = _versionParts(current);
    final length = latestParts.length > currentParts.length
        ? latestParts.length
        : currentParts.length;
    for (var i = 0; i < length; i++) {
      final l = i < latestParts.length ? latestParts[i] : 0;
      final c = i < currentParts.length ? currentParts[i] : 0;
      if (l != c) return l > c;
    }
    return false;
  }

  List<int> _versionParts(String version) {
    return version.split('.').map((part) => int.tryParse(part) ?? 0).toList();
  }

  Future<Directory> _updatesDir() async {
    final tempDir = await getTemporaryDirectory();
    final dir = Directory(p.join(tempDir.path, AppConstants.updateApkSubdirName));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Downloads the release APK, reporting progress from 0.0-100.0. Returns
  /// the downloaded file. Any failure (including cancellation) leaves no
  /// partial file behind.
  ///
  /// [isCancelled], if given, is polled between chunks; when it returns
  /// true the download stops and throws [UpdateDownloadCancelled]. Checking
  /// a flag per-chunk (rather than e.g. closing the client from outside)
  /// keeps cancellation reliable regardless of the underlying transport's
  /// exact close semantics.
  Future<File> downloadApk(
    UpdateInfo info, {
    void Function(double percent)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final dir = await _updatesDir();
    // Clear anything left over from a previous, interrupted download.
    await for (final entity in dir.list()) {
      if (entity is File) await entity.delete();
    }

    final partFile = File(p.join(dir.path, '${info.version}.apk.part'));
    final finalFile = File(p.join(dir.path, '${info.version}.apk'));

    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(info.apkDownloadUrl));
      final response = await client.send(request);
      if (response.statusCode != 200) {
        throw Exception('Download failed with status ${response.statusCode}');
      }

      final total = response.contentLength ?? info.apkSizeBytes;
      var received = 0;
      final sink = partFile.openWrite();
      try {
        await for (final chunk in response.stream) {
          if (isCancelled?.call() ?? false) {
            throw const UpdateDownloadCancelled();
          }
          sink.add(chunk);
          received += chunk.length;
          if (total > 0) onProgress?.call(received / total * 100);
        }
        await sink.flush();
      } finally {
        await sink.close();
      }
    } catch (e) {
      if (await partFile.exists()) await partFile.delete();
      rethrow;
    } finally {
      client.close();
    }

    await partFile.rename(finalFile.path);
    return finalFile;
  }
}
