import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/widgets/app_snackbar.dart';
import 'features/library/library_screen.dart';
import 'features/player/now_playing_bar.dart';
import 'features/player/providers/player_providers.dart';
import 'features/search/search_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/settings/widgets/update_dialogs.dart';
import 'services/download/download_queue_controller.dart';
import 'services/service_providers.dart';
import 'services/update/update_controller.dart';

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
      ref.read(backupServiceProvider);
      final persistence = ref.read(playbackPersistenceControllerProvider);
      persistence.restoreIfEnabled(
        ref.read(playbackRepositoryProvider),
        ref.read(trackRepositoryProvider),
      );
      _checkForUpdate();
    });
  }

  Future<void> _checkForUpdate() async {
    if (!Platform.isAndroid && !Platform.isWindows && !Platform.isLinux) return;
    final packageInfo = await ref.read(packageInfoProvider.future);
    final info = await ref
        .read(updateControllerProvider)
        .checkOnLaunchIfDue(packageInfo.version);
    if (info == null || !mounted) return;
    await showUpdateAvailableDialog(context, ref, info);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(playbackErrorsProvider, (previous, next) {
      final event = next.value;
      if (event == null) return;
      final devMode = ref.read(devModeEnabledProvider);
      showAppSnackBar(ScaffoldMessenger.of(context), devMode ? event.raw : event.friendly);
    });
    ref.listen(downloadBatchSummaryProvider, (previous, next) {
      ref.read(downloadNotificationServiceProvider).showOrUpdate(next);
      final taskbarProgress = ref.read(taskbarProgressServiceProvider);
      if (next.isActive) {
        taskbarProgress.setProgress((next.completed + next.failed) / next.total);
      } else {
        taskbarProgress.clear();
      }
    });
    final downloadsRemaining = ref.watch(downloadBatchSummaryProvider).remaining;

    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      // The mini player lives in the bottomNavigationBar slot (stacked above
      // the NavigationBar) so Scaffold's built-in floating-SnackBar avoidance
      // accounts for its height automatically, instead of a manual margin
      // hack that only knows about the "current" tab's Scaffold.
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const NowPlayingBar(),
          NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (index) => setState(() => _index = index),
            destinations: [
              const NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: downloadsRemaining > 0,
                  label: Text('$downloadsRemaining'),
                  child: const Icon(Icons.library_music),
                ),
                label: 'Library',
              ),
              const NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
            ],
          ),
        ],
      ),
    );
  }
}
