import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/ui_metrics_provider.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../data/models/track.dart';
import '../../../services/service_providers.dart';
import '../providers/library_providers.dart';

Future<void> showAddToFolderSheet(BuildContext context, Track track) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _AddToFolderSheet(track: track),
  );
}

class _AddToFolderSheet extends ConsumerWidget {
  final Track track;

  const _AddToFolderSheet({required this.track});

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

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.create_new_folder),
            title: const Text('New folder'),
            onTap: () async {
              final navigator = Navigator.of(context);
              final name = await _promptFolderName(context);
              if (name == null || name.trim().isEmpty) return;
              final repo = ref.read(folderRepositoryProvider);
              final id = await repo.createFolder(name.trim());
              await repo.addTrackToFolder(id, track);
              navigator.pop();
            },
          ),
          const Divider(height: 1),
          Flexible(
            child: foldersAsync.when(
              data: (folders) {
                if (folders.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No folders yet. Create one above.'),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: folders.length,
                  itemBuilder: (context, index) {
                    final folder = folders[index];
                    return ListTile(
                      leading: const Icon(Icons.folder),
                      title: Text(folder.name),
                      onTap: () async {
                        final navigator = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        final chromeHeight = ref.read(bottomChromeHeightProvider);
                        await ref
                            .read(folderRepositoryProvider)
                            .addTrackToFolder(folder.id, track);
                        navigator.pop();
                        showAppSnackBar(
                          messenger,
                          'Added to ${folder.name}',
                          bottomChromeHeight: chromeHeight,
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Failed to load folders: $e'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
