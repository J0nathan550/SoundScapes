import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A small animated equalizer (3 bouncing bars), used to mark the currently
/// playing track in a list. Bars keep bouncing while [animate] is true and
/// freeze mid-height when it's false (e.g. paused, but still selected).
class PlayingIndicator extends StatefulWidget {
  final bool animate;
  final Color color;
  final double size;

  const PlayingIndicator({
    super.key,
    required this.animate,
    this.color = Colors.white,
    this.size = 18,
  });

  @override
  State<PlayingIndicator> createState() => _PlayingIndicatorState();
}

class _PlayingIndicatorState extends State<PlayingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant PlayingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate == oldWidget.animate) return;
    if (widget.animate) {
      _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Each bar is offset in phase so they don't bounce in lockstep, like a
  // real level meter.
  double _barHeightFactor(int barIndex) {
    if (!widget.animate) return 0.45;
    final phase = _controller.value * 2 * math.pi + barIndex * (2 * math.pi / 3);
    return 0.25 + 0.75 * (0.5 + 0.5 * math.sin(phase));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(3, (i) {
              return Container(
                width: widget.size / 6,
                height: widget.size * _barHeightFactor(i),
                margin: EdgeInsets.symmetric(horizontal: widget.size / 18),
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(widget.size / 12),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
