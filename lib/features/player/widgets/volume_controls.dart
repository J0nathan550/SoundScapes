import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/service_providers.dart';
import '../providers/player_providers.dart';

IconData _volumeIconFor(double volume) {
  if (volume <= 0) return Icons.volume_off;
  if (volume < 0.5) return Icons.volume_down;
  return Icons.volume_up;
}

void _setVolume(WidgetRef ref, double value) {
  ref.read(audioHandlerProvider).setVolume(value);
  ref.read(settingsServiceProvider).setWindowsVolume(value);
}

/// Windows-only volume control for the mini player: a speaker icon plus a
/// narrow horizontal slider, kept well below the width of the seek bar.
class VolumeSliderCompact extends ConsumerWidget {
  const VolumeSliderCompact({super.key, this.iconColor});

  final Color? iconColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handler = ref.watch(audioHandlerProvider);
    final volume = ref.watch(volumeProvider).value ?? handler.volume;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Volume',
          icon: Icon(_volumeIconFor(volume), color: iconColor),
          onPressed: () => _setVolume(ref, volume > 0 ? 0 : 1),
        ),
        SizedBox(
          width: 80,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              min: 0,
              max: 1,
              value: volume.clamp(0.0, 1.0),
              onChanged: (value) => _setVolume(ref, value),
            ),
          ),
        ),
      ],
    );
  }
}