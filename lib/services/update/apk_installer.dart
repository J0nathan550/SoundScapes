import 'package:flutter/services.dart';

/// Hands a downloaded APK off to Android's package installer, following the
/// same native MethodChannel pattern as [YtDlpService].
class ApkInstaller {
  static const _channel = MethodChannel('soundscapes/updater');

  Future<void> installApk(String filePath) {
    return _channel.invokeMethod('installApk', {'filePath': filePath});
  }
}
