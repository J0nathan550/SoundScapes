import 'dart:io';

import 'package:flutter/services.dart';

/// Shows download progress on the taskbar/dock icon — the green overlay bar
/// Explorer draws under a running app's icon on Windows, or (on Linux) the
/// com.canonical.Unity.LauncherEntry signal Ubuntu Dock/Dash to Dock and KDE
/// Plasma's task manager honor — via the "soundscapes/window" channel (see
/// flutter_window.cpp and linux/runner/window_chrome.cc).
///
/// On Linux this has no effect on plain GNOME Shell (no dock extension) or
/// most tiling window managers — there's no equivalent surface to draw on,
/// not a bug being silently swallowed.
class TaskbarProgressService {
  static const _channel = MethodChannel('soundscapes/window');

  Future<void> setProgress(double fraction) async {
    if (!Platform.isWindows && !Platform.isLinux) return;
    try {
      await _channel.invokeMethod('setTaskbarProgress', {
        'progress': fraction.clamp(0.0, 1.0),
      });
    } on PlatformException {
      // Best-effort cosmetic touch — never worth surfacing to the user.
    }
  }

  Future<void> clear() async {
    if (!Platform.isWindows && !Platform.isLinux) return;
    try {
      await _channel.invokeMethod('clearTaskbarProgress');
    } on PlatformException {
      // Best-effort cosmetic touch — never worth surfacing to the user.
    }
  }
}
