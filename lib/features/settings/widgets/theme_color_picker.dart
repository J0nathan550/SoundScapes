import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_presets.dart';
import '../../../services/service_providers.dart';

class ThemeColorPicker extends ConsumerWidget {
  const ThemeColorPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPreset = ref.watch(themePresetProvider);
    final customColor = ref.watch(customThemeColorProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final preset in AppThemePreset.values.where((p) => p != AppThemePreset.custom))
            _Swatch(
              color: preset.seedColor!,
              monochrome: preset == AppThemePreset.monochrome,
              label: preset.label,
              selected: selectedPreset == preset,
              onTap: () => ref.read(themePresetProvider.notifier).setPreset(preset),
            ),
          _Swatch(
            color: customColor,
            label: AppThemePreset.custom.label,
            selected: selectedPreset == AppThemePreset.custom,
            icon: Icons.colorize,
            onTap: () async {
              final picked = await showDialog<Color>(
                context: context,
                builder: (_) => _CustomColorDialog(initialColor: customColor),
              );
              if (picked == null) return;
              ref.read(customThemeColorProvider.notifier).setColor(picked);
              ref.read(themePresetProvider.notifier).setPreset(AppThemePreset.custom);
            },
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  final Color color;
  final String label;
  final bool selected;
  final bool monochrome;
  final IconData? icon;
  final VoidCallback onTap;

  const _Swatch({
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
    this.monochrome = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final onColor = ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;

    return Tooltip(
      message: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            gradient: monochrome
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.black, Colors.white],
                  )
                : null,
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outlineVariant,
              width: selected ? 3 : 1,
            ),
          ),
          child: Icon(
            selected ? Icons.check : icon,
            color: monochrome ? Colors.grey : onColor,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _CustomColorDialog extends StatefulWidget {
  final Color initialColor;

  const _CustomColorDialog({required this.initialColor});

  @override
  State<_CustomColorDialog> createState() => _CustomColorDialogState();
}

class _CustomColorDialogState extends State<_CustomColorDialog> {
  late int _red = (widget.initialColor.r * 255.0).round().clamp(0, 255);
  late int _green = (widget.initialColor.g * 255.0).round().clamp(0, 255);
  late int _blue = (widget.initialColor.b * 255.0).round().clamp(0, 255);

  Color get _color => Color.fromARGB(255, _red, _green, _blue);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Custom color'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            height: 56,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: _color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            ),
          ),
          _ColorSlider(
            label: 'R',
            value: _red,
            activeColor: Colors.red,
            onChanged: (v) => setState(() => _red = v),
          ),
          _ColorSlider(
            label: 'G',
            value: _green,
            activeColor: Colors.green,
            onChanged: (v) => setState(() => _green = v),
          ),
          _ColorSlider(
            label: 'B',
            value: _blue,
            activeColor: Colors.blue,
            onChanged: (v) => setState(() => _blue = v),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_color),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

class _ColorSlider extends StatelessWidget {
  final String label;
  final int value;
  final Color activeColor;
  final ValueChanged<int> onChanged;

  const _ColorSlider({
    required this.label,
    required this.value,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 16, child: Text(label)),
        Expanded(
          child: Slider(
            min: 0,
            max: 255,
            value: value.toDouble(),
            activeColor: activeColor,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        SizedBox(width: 32, child: Text('$value')),
      ],
    );
  }
}
