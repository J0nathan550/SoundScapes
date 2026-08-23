import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../data/models/update_info.dart';
import '../../../services/update/update_controller.dart';

enum _LaunchChoice { later, update }

/// Shown automatically on launch when a newer release is found and hasn't
/// been dismissed recently. "Later" snoozes the prompt; "Update" goes
/// straight into the download+install flow.
Future<void> showUpdateAvailableDialog(
  BuildContext context,
  WidgetRef ref,
  UpdateInfo info,
) async {
  final choice = await showDialog<_LaunchChoice>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Update available'),
      content: Text('SoundScapes ${info.version} is available. Update now?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(_LaunchChoice.later),
          child: const Text('Later'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(_LaunchChoice.update),
          child: const Text('Update'),
        ),
      ],
    ),
  );

  if (choice == _LaunchChoice.later) {
    await ref.read(updateControllerProvider).recordDismissal(info.version);
    return;
  }
  if (choice == _LaunchChoice.update && context.mounted) {
    await _runDownloadAndInstall(context, ref, info);
  }
}

/// Settings-triggered check: fetches, then — if a newer version exists —
/// asks a second, explicit confirmation before downloading (deliberately
/// more deliberate than the on-launch prompt).
Future<void> showCheckForUpdatesFlow(
  BuildContext context,
  WidgetRef ref,
  String currentVersion,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final UpdateInfo? info;
  try {
    info = await ref.read(updateControllerProvider).checkNow(currentVersion);
  } catch (e) {
    showAppSnackBar(messenger, _friendlyUpdateError(e));
    return;
  }
  if (!context.mounted) return;

  if (info == null) {
    showAppSnackBar(messenger, "You're up to date.");
    return;
  }

  final confirmed = await showConfirmDialog(
    context,
    title: 'Update to ${info.version}?',
    message: 'Do you really wish to update the application?',
    confirmLabel: 'Update',
    destructive: false,
  );
  if (!confirmed || !context.mounted) return;
  await _runDownloadAndInstall(context, ref, info);
}

Future<void> _runDownloadAndInstall(
  BuildContext context,
  WidgetRef ref,
  UpdateInfo info,
) async {
  ref.read(updateDownloadControllerProvider.notifier).reset();
  unawaited(ref.read(updateDownloadControllerProvider.notifier).downloadAndInstall(info));

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _DownloadProgressDialog(),
  );
}

class _DownloadProgressDialog extends ConsumerWidget {
  const _DownloadProgressDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(updateDownloadControllerProvider, (previous, next) {
      // Once the install intent has been handed off to Android there's
      // nothing left for this dialog to show — close it.
      if (next.status == UpdateDownloadStatus.done) {
        Navigator.of(context).maybePop();
      }
    });

    final state = ref.watch(updateDownloadControllerProvider);
    final isFailed = state.status == UpdateDownloadStatus.failed;

    return PopScope(
      // Always poppable — via the button below, the system back gesture, or
      // (on some OEM skins) tapping outside — so this can never strand the
      // user on a stuck dialog with no way out. Closing it always cancels
      // whatever's still in flight; see the notifier's `cancel()`.
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) ref.read(updateDownloadControllerProvider.notifier).cancel();
      },
      child: AlertDialog(
        title: const Text('Updating SoundScapes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            switch (state.status) {
              UpdateDownloadStatus.failed => Text(_friendlyUpdateError(state.errorMessage ?? '')),
              UpdateDownloadStatus.installing => const Text('Installing update…'),
              _ => Text(
                  state.progressPercent == null
                      ? 'Starting download…'
                      : 'Downloading update… ${state.progressPercent!.toStringAsFixed(0)}%',
                ),
            },
            if (state.status == UpdateDownloadStatus.downloading ||
                state.status == UpdateDownloadStatus.installing) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: state.status == UpdateDownloadStatus.downloading
                    ? (state.progressPercent ?? 0) / 100
                    : null,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: Text(isFailed ? 'Close' : 'Cancel'),
          ),
        ],
      ),
    );
  }
}

String _friendlyUpdateError(Object error) {
  final raw = error.toString().toLowerCase();
  if (raw.contains('socketexception') ||
      raw.contains('failed host lookup') ||
      raw.contains('network')) {
    return 'No internet connection.';
  }
  if (raw.contains('403') || raw.contains('429') || raw.contains('rate limit')) {
    return "GitHub is rate-limiting update checks right now. Try again later.";
  }
  return "Couldn't complete the update. Try again later.";
}
