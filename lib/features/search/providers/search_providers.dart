import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/constants.dart';
import '../../../data/models/search_result_item.dart';
import '../../../data/models/track.dart';
import '../../../services/service_providers.dart';

enum SearchTab { videos, channels, playlists }

final searchTabProvider = StateProvider<SearchTab>((ref) => SearchTab.videos);

final searchDraftProvider = StateProvider<String>((ref) => '');

final submittedQueryProvider = StateProvider<String>((ref) => '');

final searchSuggestionsProvider = FutureProvider.autoDispose<List<String>>((
  ref,
) async {
  final draft = ref.watch(searchDraftProvider);
  if (draft.trim().length < 2) return [];

  var cancelled = false;
  ref.onDispose(() => cancelled = true);
  await Future.delayed(AppConstants.suggestionsDebounce);
  if (cancelled) return [];

  final service = ref.read(youtubeSearchServiceProvider);
  return service.suggestions(draft);
});

final searchResultsProvider = FutureProvider.autoDispose<List<Track>>((
  ref,
) async {
  final query = ref.watch(submittedQueryProvider);
  if (query.trim().isEmpty) return [];
  final service = ref.read(youtubeSearchServiceProvider);
  return service.search(query);
});

final channelSearchResultsProvider = FutureProvider.autoDispose<List<ChannelResult>>((
  ref,
) async {
  final query = ref.watch(submittedQueryProvider);
  if (query.trim().isEmpty) return [];
  final service = ref.read(youtubeSearchServiceProvider);
  return service.searchChannels(query);
});

final playlistSearchResultsProvider = FutureProvider.autoDispose<List<PlaylistResult>>((
  ref,
) async {
  final query = ref.watch(submittedQueryProvider);
  if (query.trim().isEmpty) return [];
  final service = ref.read(youtubeSearchServiceProvider);
  return service.searchPlaylists(query);
});

const _trendingSeedQueries = [
  'trending music',
  'top hits this week',
  'popular songs right now',
  'viral songs',
  'chart hits',
  'new music releases',
];

final trendingTracksProvider = FutureProvider<List<Track>>((ref) async {
  final service = ref.read(youtubeSearchServiceProvider);
  final query = (_trendingSeedQueries.toList()..shuffle()).first;
  return service.search(query);
});
