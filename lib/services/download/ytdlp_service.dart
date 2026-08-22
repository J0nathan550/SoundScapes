import 'package:flutter/services.dart';

class YtDlpResult {
  final String filePath;
  final int fileSizeBytes;

  const YtDlpResult({required this.filePath, required this.fileSizeBytes});
}

class YtDlpService {
  static const _channel = MethodChannel('soundscapes/ytdlp');

  static final Map<String, void Function(double percent)> _progressCallbacks = {};

  YtDlpService() {
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'progress') return;
      final videoId = call.arguments['videoId'] as String?;
      final percent = (call.arguments['percent'] as num?)?.toDouble();
      if (videoId == null || percent == null) return;
      _progressCallbacks[videoId]?.call(percent);
    });
  }

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

  /// Kills the native yt-dlp process for [videoId], if one is running. The
  /// in-flight [downloadAudio] call for it will then throw.
  Future<void> cancelDownload(String videoId) async {
    _progressCallbacks.remove(videoId);
    await _channel.invokeMethod('cancel', {'videoId': videoId});
  }
}
