import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../../data/models/track.dart';
import '../../../services/service_providers.dart';

class ChannelUploadsState {
  final List<Track> tracks;
  final ChannelUploadsList? page;
  final bool isLoadingMore;

  const ChannelUploadsState({
    required this.tracks,
    required this.page,
    this.isLoadingMore = false,
  });

  ChannelUploadsState copyWith({bool? isLoadingMore}) {
    return ChannelUploadsState(
      tracks: tracks,
      page: page,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class ChannelUploadsController extends AsyncNotifier<ChannelUploadsState> {
  ChannelUploadsController(this.channelId);

  final String channelId;

  @override
  Future<ChannelUploadsState> build() async {
    final service = ref.watch(youtubeSearchServiceProvider);
    final page = await service.getChannelUploadsPage(channelId);
    return ChannelUploadsState(
      tracks: page.map(service.videoToTrack).toList(),
      page: page,
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.page == null || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    final service = ref.read(youtubeSearchServiceProvider);
    final next = await current.page!.nextPage();

    state = AsyncData(
      ChannelUploadsState(
        tracks: [...current.tracks, ...?next?.map(service.videoToTrack)],
        page: next,
      ),
    );
  }
}

final channelUploadsControllerProvider =
    AsyncNotifierProvider.family<
      ChannelUploadsController,
      ChannelUploadsState,
      String
    >(ChannelUploadsController.new);

final channelMetaProvider = FutureProvider.family<Channel, String>(
  (ref, channelId) => ref.watch(youtubeSearchServiceProvider).getChannel(channelId),
);
