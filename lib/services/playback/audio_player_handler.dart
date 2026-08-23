import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

import '../../core/utils/error_format.dart';
import '../../data/models/playback_error_event.dart';

class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final Expando<MediaItem> _mediaItemExpando = Expando<MediaItem>();
  final _playbackErrors = StreamController<PlaybackErrorEvent>.broadcast();

  Stream<PlaybackErrorEvent> get playbackErrors => _playbackErrors.stream;

  Stream<void> get queueCompleted => _player.processingStateStream
      .where((state) => state == ProcessingState.completed);

  Stream<double> get volumeStream => _player.volumeStream;

  double get volume => _player.volume;

  Future<void> setVolume(double volume) => _player.setVolume(volume);

  AudioPlayerHandler() {
    _init();
  }

  void reportError(PlaybackErrorEvent event) {
    debugPrint('AudioPlayerHandler.reportError: ${event.raw}');
    playbackState.add(
      playbackState.value.copyWith(
        playing: false,
        processingState: AudioProcessingState.idle,
      ),
    );
    _playbackErrors.add(event);
  }

  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    _player.errorStream.listen((error) {
      debugPrint('AudioPlayerHandler errorStream: $error');
      playbackState.add(
        playbackState.value.copyWith(
          playing: false,
          processingState: AudioProcessingState.idle,
        ),
      );
      final title = mediaItem.value?.title ?? 'track';
      final raw = 'Couldn\'t play "$title": ${error.message}';
      _playbackErrors.add(
        PlaybackErrorEvent(
          friendly: 'Couldn\'t play "$title": ${friendlyErrorFrom(error.message ?? error).friendly}',
          raw: raw,
        ),
      );
    });

    _effectiveSequence
        .map((sequence) => sequence
            .map((s) => _mediaItemExpando[s])
            .whereType<MediaItem>()
            .toList())
        .pipe(queue);

    Rx.combineLatest4<int?, List<MediaItem>, bool, List<int>?, MediaItem?>(
      _player.currentIndexStream,
      queue,
      _player.shuffleModeEnabledStream,
      _player.shuffleIndicesStream,
      (index, queue, shuffleModeEnabled, shuffleIndices) {
        final queueIndex = _getQueueIndex(index, shuffleModeEnabled, shuffleIndices);
        return (queueIndex != null && queueIndex < queue.length)
            ? queue[queueIndex]
            : null;
      },
    ).whereType<MediaItem>().distinct().listen(mediaItem.add);

    _player.playbackEventStream.listen(_broadcastState);
    _player.shuffleModeEnabledStream.listen(
      (_) => _broadcastState(_player.playbackEvent),
    );
  }

  Stream<List<IndexedAudioSource>> get _effectiveSequence => Rx.combineLatest3<
      List<IndexedAudioSource>?, List<int>?, bool, List<IndexedAudioSource>?>(
    _player.sequenceStream,
    _player.shuffleIndicesStream,
    _player.shuffleModeEnabledStream,
    (sequence, shuffleIndices, shuffleModeEnabled) {
      if (sequence == null) return [];
      if (!shuffleModeEnabled) return sequence;
      if (shuffleIndices == null) return null;
      if (shuffleIndices.length != sequence.length) return null;
      return shuffleIndices.map((i) => sequence[i]).toList();
    },
  ).whereType<List<IndexedAudioSource>>();

  int? _getQueueIndex(
    int? currentIndex,
    bool shuffleModeEnabled,
    List<int>? shuffleIndices,
  ) {
    final effectiveIndices = _player.effectiveIndices;
    if (effectiveIndices.isEmpty) return currentIndex;
    final shuffleIndicesInv = List.filled(effectiveIndices.length, 0);
    for (var i = 0; i < effectiveIndices.length; i++) {
      shuffleIndicesInv[effectiveIndices[i]] = i;
    }
    return (shuffleModeEnabled && ((currentIndex ?? 0) < shuffleIndicesInv.length))
        ? shuffleIndicesInv[currentIndex ?? 0]
        : currentIndex;
  }

  AudioSource _itemToSource(MediaItem item) {
    final source = AudioSource.uri(Uri.parse(item.id), tag: item);
    _mediaItemExpando[source] = item;
    return source;
  }

  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    await _player.addAudioSource(_itemToSource(mediaItem));
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    await _player.addAudioSources(mediaItems.map(_itemToSource).toList());
  }

  /// Inserts [mediaItem] into the queue at [index] (e.g. 0 to place it right
  /// before whatever's currently playing). just_audio adjusts the current
  /// playback position to keep pointing at the same track, so this doesn't
  /// interrupt playback.
  Future<void> insertQueueItemAt(int index, MediaItem mediaItem) async {
    await _player.insertAudioSource(index, _itemToSource(mediaItem));
  }

  @override
  Future<void> updateQueue(List<MediaItem> queue) async {
    await _player.clearAudioSources();
    await _player.addAudioSources(queue.map(_itemToSource).toList());
  }

  @override
  Future<void> removeQueueItemAt(int index) async {
    await _player.removeAudioSourceAt(index);
  }

  Future<void> moveQueueItem(int currentIndex, int newIndex) async {
    await _player.moveAudioSource(currentIndex, newIndex);
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _player.audioSources.length) return;
    final target = _player.shuffleModeEnabled
        ? _player.shuffleIndices[index]
        : index;
    await _player.seek(Duration.zero, index: target);
  }

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    final enabled = shuffleMode == AudioServiceShuffleMode.all;
    if (enabled) await _player.shuffle();
    playbackState.add(playbackState.value.copyWith(shuffleMode: shuffleMode));
    await _player.setShuffleModeEnabled(enabled);
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    playbackState.add(playbackState.value.copyWith(repeatMode: repeatMode));
    await _player.setLoopMode(LoopMode.values[repeatMode.index]);
  }

  void _broadcastState(PlaybackEvent event) {
    final playing = _player.playing;
    final queueIndex = _getQueueIndex(
      event.currentIndex,
      _player.shuffleModeEnabled,
      _player.shuffleIndices,
    );
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState:
            const {
              ProcessingState.idle: AudioProcessingState.idle,
              ProcessingState.loading: AudioProcessingState.loading,
              ProcessingState.buffering: AudioProcessingState.buffering,
              ProcessingState.ready: AudioProcessingState.ready,
              ProcessingState.completed: AudioProcessingState.completed,
            }[_player.processingState]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: queueIndex,
      ),
    );
  }
}
