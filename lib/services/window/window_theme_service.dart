import 'dart:io';

import 'package:flutter/services.dart';

/// Pushes the app's current theme colors down to the native title bar on
/// Windows, via the "soundscapes/window" channel (see flutter_window.cpp).
///
/// Windows only exposes a colored title bar (DWMWA_CAPTION_COLOR) on Windows
/// 11 22H2+; on older Windows the native side just applies dark/light mode
/// and silently ignores the color, so this degrades gracefully.
class WindowThemeService {
  static const _channel = MethodChannel('soundscapes/window');

  Future<void> setTitleBarTheme({
    required Color caption,
    required Color text,
    required bool darkMode,
  }) async {
    if (!Platform.isWindows) return;
    try {
      await _channel.invokeMethod('setTitleBarColors', {
        'caption': caption.toARGB32(),
        'text': text.toARGB32(),
        'darkMode': darkMode,
      });
    } on PlatformException {
      // Best-effort cosmetic touch — never worth surfacing to the user.
    }
  }
}
