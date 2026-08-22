import 'package:flutter/material.dart';

/// Shows a short toast-style [SnackBar], themed to the app's accent color,
/// that floats just above the mini player / bottom navigation instead of
/// covering them, and clears itself quickly so it never gets in the way
/// for long.
///
/// Takes a [ScaffoldMessengerState] (via `ScaffoldMessenger.of(context)`)
/// rather than a [BuildContext] so callers can capture it before an async
/// gap and safely call this after awaiting something. Floating SnackBars
/// only ever render on the root [Scaffold] (see [ScaffoldMessengerState]'s
/// nested-scaffold handling), and that root Scaffold's `bottomNavigationBar`
/// holds the mini player + nav bar, so Scaffold's own floating-SnackBar
/// avoidance already keeps this clear of them — no manual offset needed.
void showAppSnackBar(ScaffoldMessengerState messenger, String message) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
    );
}
