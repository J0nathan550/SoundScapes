import 'package:drift/drift.dart';

import 'tracks_table.dart';

@DataClassName('DownloadedTrackRow')
class DownloadedTracks extends Table {
  TextColumn get trackId =>
      text().references(Tracks, #id, onDelete: KeyAction.cascade)();
  TextColumn get filePath => text()();
  TextColumn get container => text()();
  IntColumn get fileSizeBytes => integer()();
  DateTimeColumn get downloadedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {trackId};
}
