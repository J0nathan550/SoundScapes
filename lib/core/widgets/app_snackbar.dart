import 'package:flutter/material.dart';

/// Shows a short toast-style [SnackBar], themed to the app's accent color,
/// that floats just above the mini player / bottom navigation instead of
/// covering them, and clears itself quickly so it never gets in the way
/// for long.
///
/// Takes a [ScaffoldMessengerState] (via `ScaffoldMessenger.of(context)`)
/// rather than a [BuildContext] so callers can capture it before an async
/// gap and safely call this after awaiting something. [bottomChromeHeight]
/// should come from `ref.read(bottomChromeHeightProvider)` — the live
/// measured height of the mini player + bottom nav bar — so the snackbar
/// sits right above them regardless of screen/window size.
void showAppSnackBar(
  ScaffoldMessengerState messenger,
  String message, {
  double bottomChromeHeight = 0,
}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(16, 0, 16, bottomChromeHeight + 12),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
    );
}
