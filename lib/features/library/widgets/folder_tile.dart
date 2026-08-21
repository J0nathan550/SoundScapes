import 'package:flutter/material.dart';

import '../../../data/models/folder.dart';

class FolderTile extends StatelessWidget {
  final Folder folder;
  final VoidCallback onTap;

  const FolderTile({super.key, required this.folder, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: const Icon(Icons.folder),
      ),
      title: Text(folder.name),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
