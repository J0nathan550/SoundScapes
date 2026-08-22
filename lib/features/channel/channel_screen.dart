import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/service_providers.dart';
import '../library/widgets/track_list_tile.dart';
import '../player/now_playing_bar.dart';
import '../search/widgets/track_actions_row.dart';
import 'providers/channel_providers.dart';

class ChannelScreen extends ConsumerStatefulWidget {
  final String channelId;
  final String channelName;

  const ChannelScreen({
    super.key,
    required this.channelId,
    required this.channelName,
  });

  @override
  ConsumerState<ChannelScreen> createState() => _ChannelScreenState();
}

String _formatSubscribers(int count) {
  if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
  if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
  return '$count';
}

class _ChannelScreenState extends ConsumerState<ChannelScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref
          .read(channelUploadsControllerProvider(widget.channelId).notifier)
          .loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final uploadsAsync = ref.watch(
      channelUploadsControllerProvider(widget.channelId),
    );
    final subscribersCount = ref
        .watch(channelMetaProvider(widget.channelId))
        .value
        ?.subscribersCount;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.channelName),
            if (subscribersCount != null)
              Text(
                '${_formatSubscribers(subscribersCount)} subscribers',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
      bottomNavigationBar: const NowPlayingBar(applyBottomSafeArea: true),
      body: uploadsAsync.when(
        data: (state) {
          if (state.tracks.isEmpty) {
            return const Center(child: Text('No uploads found.'));
          }
          return ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            itemCount: state.tracks.length + (state.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= state.tracks.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final track = state.tracks[index];
              return TrackListTile(
                track: track,
                onTap: () => ref
                    .read(playbackRepositoryProvider)
                    .playTracks(state.tracks, startIndex: index),
                trailing: TrackActionsRow(track: track),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load channel: $e')),
      ),
    );
  }
}
