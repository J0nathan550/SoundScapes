import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/providers/ui_metrics_provider.dart';
import '../../../core/utils/duration_format.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../services/playback/sleep_timer_controller.dart';
import '../providers/player_providers.dart';
import 'duration_picker_dialog.dart';

Future<void> showSleepTimerSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => const SleepTimerSheet(),
  );
}

class SleepTimerSheet extends ConsumerWidget {
  const SleepTimerSheet({super.key});

  void _start(BuildContext context, WidgetRef ref, Duration duration) {
    final messenger = ScaffoldMessenger.of(context);
    final chromeHeight = ref.read(bottomChromeHeightProvider);
    ref.read(sleepTimerControllerProvider.notifier).startDuration(duration);
    Navigator.of(context).pop();
    showAppSnackBar(
      messenger,
      'Sleep timer set for ${presetLabel(duration)}',
      bottomChromeHeight: chromeHeight,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sleepTimerControllerProvider);
    final hasMediaItem = ref.watch(currentMediaItemProvider).value != null;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state.isActive) ...[
            ListTile(
              leading: const Icon(Icons.bedtime),
              title: Text(
                state.mode == SleepTimerMode.endOfTrack
                    ? 'Ends after this track'
                    : 'Ends in ${formatDuration(state.remaining ?? Duration.zero)}',
              ),
              trailing: TextButton(
                onPressed: () {
                  ref.read(sleepTimerControllerProvider.notifier).cancel();
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel timer'),
              ),
            ),
            const Divider(height: 1),
          ],
          for (final preset in AppConstants.sleepTimerPresets)
            ListTile(
              leading: const Icon(Icons.bedtime_outlined),
              title: Text(presetLabel(preset)),
              onTap: () => _start(context, ref, preset),
            ),
          if (hasMediaItem)
            ListTile(
              leading: const Icon(Icons.music_note_outlined),
              title: const Text('End of current track'),
              onTap: () {
                final messenger = ScaffoldMessenger.of(context);
                final chromeHeight = ref.read(bottomChromeHeightProvider);
                ref.read(sleepTimerControllerProvider.notifier).startEndOfTrack();
                Navigator.of(context).pop();
                showAppSnackBar(
                  messenger,
                  'Sleep timer set for the end of this track',
                  bottomChromeHeight: chromeHeight,
                );
              },
            ),
          ListTile(
            leading: const Icon(Icons.more_time),
            title: const Text('Custom…'),
            onTap: () async {
              final duration = await showCustomDurationPicker(context);
              if (duration == null || !context.mounted) return;
              _start(context, ref, duration);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

String presetLabel(Duration d) {
  if (d.inMinutes < 60) return '${d.inMinutes} minutes';
  final hours = d.inMinutes ~/ 60;
  final minutes = d.inMinutes % 60;
  if (minutes == 0) return hours == 1 ? '1 hour' : '$hours hours';
  return '${hours}h ${minutes}min';
}
