import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/folder.dart';
import '../../services/service_providers.dart';
import 'downloaded_screen.dart';
import 'folder_detail_screen.dart';
import 'providers/library_providers.dart';
import 'widgets/folder_tile.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  Future<String?> _promptFolderName(BuildContext context) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Folder name'),
          onSubmitted: (value) => Navigator.of(ctx).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(foldersProvider);
    final likedFolderId = ref.watch(likedSongsFolderIdProvider).value;
    final likedCount = likedFolderId == null
        ? null
        : ref.watch(folderTracksProvider(likedFolderId)).value?.length;
    final downloadedCount = ref.watch(downloadedTracksProvider).value?.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Library')),
      body: ListView(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: const Icon(Icons.favorite),
            ),
            title: const Text('Liked Songs'),
            subtitle: Text('${likedCount ?? 0} songs'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final id = await ref.read(likedSongsFolderIdProvider.future);
              if (!context.mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => FolderDetailScreen(
                    folder: Folder(
                      id: id,
                      name: 'Liked Songs',
                      createdAt: DateTime.now(),
                      isSystem: true,
                    ),
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: const Icon(Icons.download_done),
            ),
            title: const Text('Downloaded'),
            subtitle: Text('${downloadedCount ?? 0} songs'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DownloadedScreen()),
            ),
          ),
          const Divider(),
          foldersAsync.when(
            data: (folders) {
              if (folders.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('No folders yet. Tap + to create one.'),
                  ),
                );
              }
              return Column(
                children: [
                  for (final folder in folders)
                    FolderTile(
                      folder: folder,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FolderDetailScreen(folder: folder),
                        ),
                      ),
                    ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Failed to load folders: $e')),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final name = await _promptFolderName(context);
          if (name == null || name.trim().isEmpty) return;
          await ref.read(folderRepositoryProvider).createFolder(name.trim());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
