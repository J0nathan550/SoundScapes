class Folder {
  final int id;
  final String name;
  final DateTime createdAt;
  final bool isSystem;

  const Folder({
    required this.id,
    required this.name,
    required this.createdAt,
    this.isSystem = false,
  });
}
