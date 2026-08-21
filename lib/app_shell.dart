import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/ui_metrics_provider.dart';
import 'core/widgets/app_snackbar.dart';
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
  final _playerBarKey = GlobalKey();
  final _navBarKey = GlobalKey();

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
      _measureBottomChrome();
    });
  }

  void _measureBottomChrome() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final playerHeight =
          (_playerBarKey.currentContext?.findRenderObject() as RenderBox?)
              ?.size
              .height ??
          0;
      final navHeight =
          (_navBarKey.currentContext?.findRenderObject() as RenderBox?)
              ?.size
              .height ??
          0;
      final height = playerHeight + navHeight;
      if (ref.read(bottomChromeHeightProvider) != height) {
        ref.read(bottomChromeHeightProvider.notifier).state = height;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(playbackErrorsProvider, (previous, next) {
      final message = next.value;
      if (message == null) return;
      showAppSnackBar(
        ScaffoldMessenger.of(context),
        message,
        bottomChromeHeight: ref.read(bottomChromeHeightProvider),
      );
    });
    ref.listen(currentMediaItemProvider, (previous, next) => _measureBottomChrome());

    return Scaffold(
      body: Column(
        children: [
          Expanded(child: IndexedStack(index: _index, children: _screens)),
          NowPlayingBar(key: _playerBarKey),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        key: _navBarKey,
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
