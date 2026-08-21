import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../data/models/search_result_item.dart';
import '../../channel/channel_screen.dart';

class ChannelResultTile extends StatelessWidget {
  final ChannelResult channel;

  const ChannelResultTile({super.key, required this.channel});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        backgroundImage: channel.thumbnailUrl.isEmpty
            ? null
            : CachedNetworkImageProvider(channel.thumbnailUrl),
        child: channel.thumbnailUrl.isEmpty ? const Icon(Icons.person) : null,
      ),
      title: Text(channel.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: switch (channel.videoCount) {
        final count? => Text('$count videos'),
        null when channel.description.isNotEmpty => Text(
          channel.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        null => null,
      },
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChannelScreen(
            channelId: channel.id,
            channelName: channel.name,
          ),
        ),
      ),
    );
  }
}
