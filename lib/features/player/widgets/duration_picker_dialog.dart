import 'package:flutter/material.dart';

Future<Duration?> showCustomDurationPicker(BuildContext context) {
  return showDialog<Duration>(
    context: context,
    builder: (_) => const _DurationPickerDialog(),
  );
}

class _DurationPickerDialog extends StatefulWidget {
  const _DurationPickerDialog();

  @override
  State<_DurationPickerDialog> createState() => _DurationPickerDialogState();
}

class _DurationPickerDialogState extends State<_DurationPickerDialog> {
  int _hours = 0;
  int _minutes = 0;

  @override
  Widget build(BuildContext context) {
    final canStart = _hours > 0 || _minutes > 0;
    return AlertDialog(
      title: const Text('Custom sleep timer'),
      content: SizedBox(
        height: 180,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: _Wheel(
                itemCount: 24,
                label: 'h',
                onChanged: (v) => setState(() => _hours = v),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Wheel(
                itemCount: 12,
                step: 5,
                label: 'min',
                onChanged: (v) => setState(() => _minutes = v),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: canStart
              ? () => Navigator.of(context).pop(
                  Duration(hours: _hours, minutes: _minutes),
                )
              : null,
          child: const Text('Start'),
        ),
      ],
    );
  }
}

class _Wheel extends StatelessWidget {
  final int itemCount;
  final int step;
  final String label;
  final ValueChanged<int> onChanged;

  const _Wheel({
    required this.itemCount,
    required this.label,
    required this.onChanged,
    this.step = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListWheelScrollView.useDelegate(
            itemExtent: 40,
            diameterRatio: 1.2,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (index) => onChanged(index * step),
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: itemCount,
              builder: (context, index) => Center(
                child: Text(
                  '${index * step}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
