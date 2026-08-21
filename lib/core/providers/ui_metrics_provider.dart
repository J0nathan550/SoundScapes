import 'package:flutter_riverpod/legacy.dart';

/// Combined on-screen height of the mini player + bottom navigation bar,
/// measured live by [AppShell] so anything anchored to the bottom of the
/// screen (like [showAppSnackBar]) can sit exactly above them instead of
/// guessing a fixed offset that breaks on different window/screen sizes.
final bottomChromeHeightProvider = StateProvider<double>((ref) => 0);
