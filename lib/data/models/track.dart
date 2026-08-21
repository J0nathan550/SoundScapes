class Track {
  final String id;
  final String title;
  final String author;
  final Duration duration;
  final String thumbnailUrl;
  final bool isDownloaded;
  final String? localFilePath;

  const Track({
    required this.id,
    required this.title,
    required this.author,
    required this.duration,
    required this.thumbnailUrl,
    this.isDownloaded = false,
    this.localFilePath,
  });

  Track copyWith({bool? isDownloaded, String? localFilePath}) {
    return Track(
      id: id,
      title: title,
      author: author,
      duration: duration,
      thumbnailUrl: thumbnailUrl,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      localFilePath: localFilePath ?? this.localFilePath,
    );
  }
}
