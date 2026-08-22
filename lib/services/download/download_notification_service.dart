import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../data/models/download_batch_summary.dart';

/// Shows a single, continuously-updated system notification summarizing the
/// current download batch (downloaded / failed / remaining) while the app
/// process is alive — there's no foreground service or WorkManager involved,
/// so this can't survive the app being killed, only backgrounded.
class DownloadNotificationService {
  static const _notificationId = 7526;
  static const _channelId = 'com.j0nathan550.soundscapes.channel.downloads';

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _permissionRequested = false;

  Future<void> _ensureReady() async {
    if (_initialized) return;
    _initialized = true;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
      ),
    );
    if (_permissionRequested) return;
    _permissionRequested = true;
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> showOrUpdate(DownloadBatchSummary summary) async {
    if (!Platform.isAndroid) return;
    if (summary.isEmpty) {
      await cancel();
      return;
    }
    await _ensureReady();

    final segments = [
      if (summary.completed > 0) '${summary.completed} downloaded',
      if (summary.failed > 0) '${summary.failed} failed',
      if (summary.remaining > 0) '${summary.remaining} remaining',
    ];

    await _plugin.show(
      id: _notificationId,
      title: summary.isActive ? 'Downloading tracks…' : 'Downloads finished',
      body: segments.join(' · '),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Downloads',
          channelDescription: "Shows progress while this session's downloads run.",
          importance: Importance.low,
          priority: Priority.low,
          playSound: false,
          enableVibration: false,
          onlyAlertOnce: true,
          ongoing: summary.isActive,
          autoCancel: !summary.isActive,
          showProgress: true,
          maxProgress: summary.total,
          progress: summary.completed + summary.failed,
        ),
      ),
    );
  }

  Future<void> cancel() async {
    if (!Platform.isAndroid || !_initialized) return;
    await _plugin.cancel(id: _notificationId);
  }
}
