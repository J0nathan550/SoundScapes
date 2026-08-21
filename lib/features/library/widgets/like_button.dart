import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/track.dart';
import '../../../services/service_providers.dart';
import '../providers/library_providers.dart';

class LikeButton extends ConsumerWidget {
  final Track track;

  const LikeButton({super.key, required this.track});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liked = ref.watch(isTrackLikedProvider(track.id)).value ?? false;
    return IconButton(
      tooltip: liked ? 'Unlike' : 'Like',
      icon: Icon(
        liked ? Icons.favorite : Icons.favorite_border,
        color: liked ? Colors.redAccent : null,
      ),
      onPressed: () => ref.read(folderRepositoryProvider).toggleLiked(track),
    );
  }
}
