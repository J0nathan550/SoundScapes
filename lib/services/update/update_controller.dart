import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/update_info.dart';
import '../service_providers.dart';
import '../settings/settings_service.dart';
import 'update_service.dart';

/// Coordinates checking for updates against the dismissal snooze recorded in
/// Settings. Two entry points: a quiet background check for the on-launch
/// prompt, and an explicit check for the Settings "Check for updates" tile.
class UpdateController {
  UpdateController(this._updateService, this._settingsService);

  final UpdateService _updateService;
  final SettingsService _settingsService;

  /// Returns the latest release if the user should be prompted about it now:
  /// there IS a newer version, and either it's different from the one they
  /// last dismissed, or a day has passed since that dismissal. Swallows
  /// failures (no internet, GitHub rate limit) since this runs quietly on
  /// every launch and shouldn't surface an error the user didn't ask for.
  Future<UpdateInfo?> checkOnLaunchIfDue(String currentVersion) async {
    final UpdateInfo? info;
    try {
      info = await _updateService.fetchLatestIfNewer(currentVersion);
    } catch (_) {
      return null;
    }
    if (info == null) return null;

    final dismissedVersion = _settingsService.dismissedUpdateVersion;
    final dismissedAt = _settingsService.dismissedUpdateAt;
    final sameVersionRecentlyDismissed = dismissedVersion == info.version &&
        dismissedAt != null &&
        DateTime.now().difference(dismissedAt) < const Duration(days: 1);
    if (sameVersionRecentlyDismissed) return null;

    return info;
  }

  /// Explicit, user-triggered check. Ignores any prior dismissal and lets
  /// failures propagate so the caller can show them.
  Future<UpdateInfo?> checkNow(String currentVersion) {
    return _updateService.fetchLatestIfNewer(currentVersion);
  }

  Future<void> recordDismissal(String version) {
    return _settingsService.setDismissedUpdate(version, DateTime.now());
  }
}

final updateControllerProvider = Provider<UpdateController>((ref) {
  return UpdateController(
    ref.watch(updateServiceProvider),
    ref.watch(settingsServiceProvider),
  );
});

enum UpdateDownloadStatus { idle, downloading, installing, done, failed }

class UpdateDownloadState {
  final UpdateDownloadStatus status;
  final double? progressPercent;
  final String? errorMessage;

  const UpdateDownloadState({
    this.status = UpdateDownloadStatus.idle,
    this.progressPercent,
    this.errorMessage,
  });
}

class UpdateDownloadController extends Notifier<UpdateDownloadState> {
  bool _cancelRequested = false;

  @override
  UpdateDownloadState build() => const UpdateDownloadState();

  Future<void> downloadAndInstall(UpdateInfo info) async {
    _cancelRequested = false;
    state = const UpdateDownloadState(
      status: UpdateDownloadStatus.downloading,
      progressPercent: 0,
    );
    try {
      final file = await ref.read(updateServiceProvider).downloadApk(
        info,
        isCancelled: () => _cancelRequested,
        onProgress: (percent) {
          state = UpdateDownloadState(
            status: UpdateDownloadStatus.downloading,
            progressPercent: percent,
          );
        },
      );
      state = const UpdateDownloadState(status: UpdateDownloadStatus.installing);
      // No explicit install-permission request here: firing the install
      // intent below already makes Android show its own "allow from this
      // source" screen inline when the permission isn't granted, so this
      // never blocks on anything we don't control.
      await ref.read(apkInstallerProvider).installApk(file.path);
      state = const UpdateDownloadState(status: UpdateDownloadStatus.done);
    } on UpdateDownloadCancelled {
      state = const UpdateDownloadState();
    } catch (e) {
      state = UpdateDownloadState(
        status: UpdateDownloadStatus.failed,
        errorMessage: e.toString(),
      );
    }
  }

  /// Stops an in-progress download (checked cooperatively between chunks)
  /// and resets to idle. Safe to call at any time, including when nothing
  /// is running — this is the escape hatch that keeps the update dialog
  /// from ever getting permanently stuck.
  void cancel() {
    _cancelRequested = true;
    state = const UpdateDownloadState();
  }

  void reset() => state = const UpdateDownloadState();
}

final updateDownloadControllerProvider =
    NotifierProvider<UpdateDownloadController, UpdateDownloadState>(
      UpdateDownloadController.new,
    );
