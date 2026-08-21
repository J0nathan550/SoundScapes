import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/search_providers.dart';
import 'widgets/search_result_tile.dart';
import 'widgets/suggestions_list.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _hasFocus = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    _controller.value = TextEditingValue(
      text: trimmed,
      selection: TextSelection.collapsed(offset: trimmed.length),
    );
    ref.read(searchDraftProvider.notifier).state = trimmed;
    ref.read(submittedQueryProvider.notifier).state = trimmed;
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final suggestionsAsync = ref.watch(searchSuggestionsProvider);
    final resultsAsync = ref.watch(searchResultsProvider);
    final draft = ref.watch(searchDraftProvider);
    final submittedQuery = ref.watch(submittedQueryProvider);
    final showSuggestions = _hasFocus && draft.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Search YouTube',
            border: InputBorder.none,
          ),
          onChanged: (value) =>
              ref.read(searchDraftProvider.notifier).state = value,
          onSubmitted: _submit,
        ),
        actions: [
          if (draft.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _controller.clear();
                ref.read(searchDraftProvider.notifier).state = '';
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          resultsAsync.when(
            data: (results) {
              if (results.isNotEmpty) {
                return ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) =>
                      SearchResultTile(track: results[index]),
                );
              }
              if (submittedQuery.trim().isEmpty) {
                return const _TrendingList();
              }
              return const Center(child: Text('No results found'));
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Search failed: $e')),
          ),
          if (showSuggestions)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: Material(
                elevation: 4,
                child: suggestionsAsync.when(
                  data: (suggestions) {
                    if (suggestions.isEmpty) return const SizedBox.shrink();
                    return ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 320),
                      child: SuggestionsList(
                        suggestions: suggestions,
                        onSelected: _submit,
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TrendingList extends ConsumerWidget {
  const _TrendingList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendingAsync = ref.watch(trendingTracksProvider);
    return trendingAsync.when(
      data: (tracks) {
        if (tracks.isEmpty) {
          return const Center(child: Text('Search for a song or video'));
        }
        return ListView.builder(
          itemCount: tracks.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  'Trending',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            }
            return SearchResultTile(track: tracks[index - 1]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('Search for a song or video')),
    );
  }
}
