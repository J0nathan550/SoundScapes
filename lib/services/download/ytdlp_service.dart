import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class YtDlpResult {
  final String filePath;
  final int fileSizeBytes;

  const YtDlpResult({required this.filePath, required this.fileSizeBytes});
}

abstract class YtDlpService {
  factory YtDlpService() {
    if (Platform.isAndroid) return _AndroidYtDlpService();
    if (Platform.isWindows) return _WindowsYtDlpService();
    throw UnsupportedError('YtDlpService has no implementation for this platform yet');
  }

  Future<YtDlpResult> downloadAudio({
    required String videoId,
    required String outputPathNoExt,
    void Function(double percent)? onProgress,
  });

  /// Kills the native yt-dlp process for [videoId], if one is running. The
  /// in-flight [downloadAudio] call for it will then throw.
  Future<void> cancelDownload(String videoId);
}

/// Android implementation, backed by the "soundscapes/ytdlp" MethodChannel
/// (see MainActivity.kt), which runs the bundled youtubedl-android binary.
class _AndroidYtDlpService implements YtDlpService {
  static const _channel = MethodChannel('soundscapes/ytdlp');

  static final Map<String, void Function(double percent)> _progressCallbacks = {};

  _AndroidYtDlpService() {
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'progress') return;
      final videoId = call.arguments['videoId'] as String?;
      final percent = (call.arguments['percent'] as num?)?.toDouble();
      if (videoId == null || percent == null) return;
      _progressCallbacks[videoId]?.call(percent);
    });
  }

  @override
  Future<YtDlpResult> downloadAudio({
    required String videoId,
    required String outputPathNoExt,
    void Function(double percent)? onProgress,
  }) async {
    if (onProgress != null) _progressCallbacks[videoId] = onProgress;
    try {
      final result = await _channel.invokeMethod<Map>('downloadAudio', {
        'videoId': videoId,
        'outputPathNoExt': outputPathNoExt,
      });
      return YtDlpResult(
        filePath: result!['filePath'] as String,
        fileSizeBytes: (result['fileSizeBytes'] as num).toInt(),
      );
    } finally {
      _progressCallbacks.remove(videoId);
    }
  }

  @override
  Future<void> cancelDownload(String videoId) async {
    _progressCallbacks.remove(videoId);
    await _channel.invokeMethod('cancel', {'videoId': videoId});
  }
}

/// Windows implementation, backed by the standalone yt-dlp.exe, since there's
/// no Android-style bundled binary for desktop. The executable is fetched
/// once from yt-dlp's GitHub releases and cached under the app support
/// directory — the same "download a GitHub release asset" approach
/// [UpdateService] already uses for app updates.
class _WindowsYtDlpService implements YtDlpService {
  final Map<String, Process> _runningProcesses = {};

  Future<File> _ensureBinary() async {
    final supportDir = await getApplicationSupportDirectory();
    final binDir = Directory(p.join(supportDir.path, 'bin'));
    if (!await binDir.exists()) await binDir.create(recursive: true);
    final file = File(p.join(binDir.path, 'yt-dlp.exe'));
    if (await file.exists()) return file;

    final response = await http.get(
      Uri.parse('https://api.github.com/repos/yt-dlp/yt-dlp/releases/latest'),
      headers: const {'Accept': 'application/vnd.github+json'},
    );
    if (response.statusCode != 200) {
      throw Exception('GitHub returned ${response.statusCode} while fetching yt-dlp');
    }
    final body = json.decode(response.body) as Map<String, dynamic>;
    final assets = (body['assets'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final asset = assets.cast<Map<String, dynamic>?>().firstWhere(
      (a) => a?['name'] == 'yt-dlp.exe',
      orElse: () => null,
    );
    if (asset == null) {
      throw Exception('No yt-dlp.exe asset found in the latest yt-dlp release');
    }
    final bytes = await http.readBytes(Uri.parse(asset['browser_download_url'] as String));
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  @override
  Future<YtDlpResult> downloadAudio({
    required String videoId,
    required String outputPathNoExt,
    void Function(double percent)? onProgress,
  }) async {
    final binary = await _ensureBinary();
    final process = await Process.start(binary.path, [
      // Prefer m4a/AAC over the webm/opus yt-dlp would otherwise pick: it
      // plays natively via WinRT MediaPlayer, whereas opus-in-webm needs the
      // (not always installed) "Web Media Extensions" Windows feature.
      '-f', 'bestaudio[ext=m4a]/bestaudio',
      '-o', '$outputPathNoExt.%(ext)s',
      // See the equivalent option in MainActivity.kt's handleDownloadAudio:
      // avoids YouTube's SABR streaming, which withholds direct-URL formats
      // without a PO Token, by using clients that don't require one.
      '--extractor-args', 'youtube:player_client=default,android,tv',
      '--no-playlist',
      '--newline',
      'https://www.youtube.com/watch?v=$videoId',
    ]);
    _runningProcesses[videoId] = process;

    final stderrLines = <String>[];
    final progressPattern = RegExp(r'\[download\]\s+([\d.]+)%');
    process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
      final match = progressPattern.firstMatch(line);
      if (match != null) onProgress?.call(double.tryParse(match.group(1)!) ?? 0);
    });
    process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(stderrLines.add);

    try {
      final exitCode = await process.exitCode;
      if (exitCode != 0) {
        throw Exception('yt-dlp exited with code $exitCode: ${stderrLines.join('\n')}');
      }
      final outputFile = await _findOutputFile(outputPathNoExt);
      if (outputFile == null) {
        throw Exception('yt-dlp produced no output file');
      }
      return YtDlpResult(filePath: outputFile.path, fileSizeBytes: await outputFile.length());
    } finally {
      _runningProcesses.remove(videoId);
    }
  }

  Future<File?> _findOutputFile(String outputPathNoExt) async {
    final dir = Directory(p.dirname(outputPathNoExt));
    if (!await dir.exists()) return null;
    final prefix = '${p.basename(outputPathNoExt)}.';
    await for (final entity in dir.list()) {
      if (entity is File && p.basename(entity.path).startsWith(prefix)) return entity;
    }
    return null;
  }

  @override
  Future<void> cancelDownload(String videoId) async {
    _runningProcesses.remove(videoId)?.kill();
  }
}
