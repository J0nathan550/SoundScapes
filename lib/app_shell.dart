import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/library/library_screen.dart';
import 'features/player/now_playing_bar.dart';
import 'features/player/providers/player_providers.dart';
import 'features/search/search_screen.dart';
import 'features/settings/settings_screen.dart';
import 'services/service_providers.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  static const _screens = [
    SearchScreen(),
    LibraryScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(autoplayControllerProvider);
      final persistence = ref.read(playbackPersistenceControllerProvider);
      persistence.restoreIfEnabled(
        ref.read(playbackRepositoryProvider),
        ref.read(trackRepositoryProvider),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(playbackErrorsProvider, (previous, next) {
      final message = next.value;
      if (message == null) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    });

    return Scaffold(
      body: Column(
        children: [
          Expanded(child: IndexedStack(index: _index, children: _screens)),
          const NowPlayingBar(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(
            icon: Icon(Icons.library_music),
            label: 'Library',
          ),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
