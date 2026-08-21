import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/byte_format.dart';
import '../../core/utils/duration_format.dart';
import '../../services/playback/sleep_timer_controller.dart';
import '../../services/service_providers.dart';
import '../player/widgets/sleep_timer_sheet.dart';
import 'widgets/theme_color_picker.dart';
import 'widgets/youtube_login_webview.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final autoplay = ref.watch(autoplayEnabledProvider);
    final resumePlayback = ref.watch(resumePlaybackEnabledProvider);
    final authCookie = ref.watch(youtubeAuthCookieProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('Appearance'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.brightness_auto),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode),
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (selected) => ref
                  .read(themeModeProvider.notifier)
                  .setThemeMode(selected.first),
            ),
          ),
          const SizedBox(height: 12),
          const ThemeColorPicker(),
          const SizedBox(height: 8),
          const _SectionHeader('Playback'),
          SwitchListTile(
            title: const Text('Autoplay'),
            subtitle: const Text(
              'Keep playing similar tracks automatically when the queue ends',
            ),
            value: autoplay,
            onChanged: (value) =>
                ref.read(autoplayEnabledProvider.notifier).setEnabled(value),
          ),
          SwitchListTile(
            title: const Text('Resume playback on launch'),
            subtitle: const Text(
              'Reopen to the last track you were playing, paused',
            ),
            value: resumePlayback,
            onChanged: (value) => ref
                .read(resumePlaybackEnabledProvider.notifier)
                .setEnabled(value),
          ),
          const _SectionHeader('Sleep Timer'),
          Consumer(
            builder: (context, ref, _) {
              final sleepTimer = ref.watch(sleepTimerControllerProvider);
              return ListTile(
                leading: const Icon(Icons.bedtime_outlined),
                title: const Text('Sleep timer'),
                subtitle: Text(
                  !sleepTimer.isActive
                      ? 'Off'
                      : sleepTimer.mode == SleepTimerMode.endOfTrack
                      ? 'Ends after this track'
                      : 'Ends in ${formatDuration(sleepTimer.remaining ?? Duration.zero)}',
                ),
                trailing: sleepTimer.isActive
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Cancel timer',
                        onPressed: () =>
                            ref.read(sleepTimerControllerProvider.notifier).cancel(),
                      )
                    : const Icon(Icons.chevron_right),
                onTap: () => showSleepTimerSheet(context),
              );
            },
          ),
          const _SectionHeader('Storage'),
          Consumer(
            builder: (context, ref, _) {
              final sizeAsync = ref.watch(cacheSizeBytesProvider);
              return ListTile(
                leading: const Icon(Icons.storage),
                title: const Text('Clear cache'),
                subtitle: Text(
                  sizeAsync.when(
                    data: (bytes) =>
                        'Tracks played (but not downloaded) use ${formatBytes(bytes)}',
                    loading: () => 'Calculating…',
                    error: (_, _) => 'Unable to read cache size',
                  ),
                ),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Clear cache?'),
                      content: const Text(
                        'Frees up space used by tracks you played but never explicitly '
                        'downloaded. Anything in your Downloaded library is unaffected.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await ref.read(cacheServiceProvider).clearCache();
                    ref.invalidate(cacheSizeBytesProvider);
                  }
                },
              );
            },
          ),
          const _SectionHeader('Account'),
          authCookie.when(
            data: (cookie) => cookie == null
                ? ListTile(
                    leading: const Icon(Icons.login),
                    title: const Text('Sign in with YouTube'),
                    subtitle: const Text(
                      'Reduces rate-limiting on search and playback',
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const YoutubeLoginWebView(),
                      ),
                    ),
                  )
                : ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: const Text('Signed in'),
                    trailing: TextButton(
                      onPressed: () =>
                          ref.read(youtubeAuthCookieProvider.notifier).signOut(),
                      child: const Text('Sign out'),
                    ),
                  ),
            loading: () => const ListTile(
              leading: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              title: Text('Checking sign-in status…'),
            ),
            error: (e, _) => ListTile(
              leading: const Icon(Icons.error_outline),
              title: const Text('Sign in with YouTube'),
              subtitle: Text('$e'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const YoutubeLoginWebView()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
