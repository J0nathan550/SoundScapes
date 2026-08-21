import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../service_providers.dart';

enum SleepTimerMode { duration, endOfTrack }

class SleepTimerState {
  final bool isActive;
  final SleepTimerMode? mode;
  final Duration? remaining;

  const SleepTimerState({this.isActive = false, this.mode, this.remaining});
}

class SleepTimerController extends Notifier<SleepTimerState> {
  Timer? _tickTimer;
  DateTime? _firesAt;
  List<StreamSubscription> _subscriptions = const [];

  @override
  SleepTimerState build() {
    ref.onDispose(_cancelInternal);
    return const SleepTimerState();
  }

  void startDuration(Duration duration) {
    _cancelInternal();
    _firesAt = DateTime.now().add(duration);
    state = SleepTimerState(
      isActive: true,
      mode: SleepTimerMode.duration,
      remaining: duration,
    );
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void startEndOfTrack() {
    _cancelInternal();
    final handler = ref.read(audioHandlerProvider);
    final startTrackId = handler.mediaItem.valueOrNull?.extras?['trackId'] as String?;

    state = const SleepTimerState(isActive: true, mode: SleepTimerMode.endOfTrack);

    final mediaItemSub = handler.mediaItem.listen((item) {
      final id = item?.extras?['trackId'] as String?;
      if (id != startTrackId) _fire();
    });
    final completedSub = handler.queueCompleted.listen((_) => _fire());
    _subscriptions = [mediaItemSub, completedSub];
  }

  void cancel() {
    _cancelInternal();
    state = const SleepTimerState();
  }

  void _tick() {
    final firesAt = _firesAt;
    if (firesAt == null) return;
    final remaining = firesAt.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      _fire();
      return;
    }
    state = SleepTimerState(
      isActive: true,
      mode: SleepTimerMode.duration,
      remaining: remaining,
    );
  }

  void _fire() {
    ref.read(audioHandlerProvider).pause();
    cancel();
  }

  void _cancelInternal() {
    _tickTimer?.cancel();
    _tickTimer = null;
    _firesAt = null;
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions = const [];
  }
}

final sleepTimerControllerProvider =
    NotifierProvider<SleepTimerController, SleepTimerState>(
      SleepTimerController.new,
    );
