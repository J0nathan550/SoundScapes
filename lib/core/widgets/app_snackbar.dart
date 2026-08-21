import 'package:flutter/material.dart';

/// Shows a short, black & white toast-style [SnackBar] that floats above
/// the mini player / bottom navigation instead of covering them, and
/// clears itself quickly so it never gets in the way for long.
///
/// Takes a [ScaffoldMessengerState] (via `ScaffoldMessenger.of(context)`)
/// rather than a [BuildContext] so callers can capture it before an async
/// gap and safely call this after awaiting something.
void showAppSnackBar(
  ScaffoldMessengerState messenger,
  String message, {
  double bottomInset = 0,
  bool avoidPlayerBar = true,
}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          bottomInset + (avoidPlayerBar ? 160 : 16),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
    );
}
