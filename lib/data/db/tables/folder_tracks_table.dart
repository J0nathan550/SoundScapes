import 'package:drift/drift.dart';

import 'folders_table.dart';
import 'tracks_table.dart';

@DataClassName('FolderTrackRow')
class FolderTracks extends Table {
  IntColumn get folderId =>
      integer().references(Folders, #id, onDelete: KeyAction.cascade)();
  TextColumn get trackId =>
      text().references(Tracks, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();

  @override
  Set<Column> get primaryKey => {folderId, trackId};
}
