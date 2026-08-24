import 'dart:io';

import 'package:flutter/services.dart';

/// Shows download progress on the Windows taskbar icon (the green overlay
/// bar Explorer draws under a running app's icon), via the
/// "soundscapes/window" channel (see flutter_window.cpp).
class TaskbarProgressService {
  static const _channel = MethodChannel('soundscapes/window');

  Future<void> setProgress(double fraction) async {
    if (!Platform.isWindows) return;
    try {
      await _channel.invokeMethod('setTaskbarProgress', {
        'progress': fraction.clamp(0.0, 1.0),
      });
    } on PlatformException {
      // Best-effort cosmetic touch — never worth surfacing to the user.
    }
  }

  Future<void> clear() async {
    if (!Platform.isWindows) return;
    try {
      await _channel.invokeMethod('clearTaskbarProgress');
    } on PlatformException {
      // Best-effort cosmetic touch — never worth surfacing to the user.
    }
  }
}
