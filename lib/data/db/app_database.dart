import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../models/folder.dart' as domain;
import '../models/track.dart' as domain;
import 'tables/downloaded_tracks_table.dart';
import 'tables/folder_tracks_table.dart';
import 'tables/folders_table.dart';
import 'tables/tracks_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Tracks, Folders, FolderTracks, DownloadedTracks])
final class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? implementation])
    : super(implementation ?? driftDatabase(name: 'soundscapes'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(folders, folders.isSystem);
      }
    },
  );

  domain.Track _trackFromRows(TrackRow row, DownloadedTrackRow? downloaded) {
    return domain.Track(
      id: row.id,
      title: row.title,
      author: row.author,
      duration: Duration(milliseconds: row.durationMs),
      thumbnailUrl: row.thumbnailUrl,
      isDownloaded: downloaded != null,
      localFilePath: downloaded?.filePath,
    );
  }

  Future<void> upsertTrack(domain.Track track) {
    return into(tracks).insertOnConflictUpdate(
      TracksCompanion.insert(
        id: track.id,
        title: track.title,
        author: track.author,
        durationMs: track.duration.inMilliseconds,
        thumbnailUrl: track.thumbnailUrl,
      ),
    );
  }

  domain.Folder _folderFromRow(FolderRow row) {
    return domain.Folder(
      id: row.id,
      name: row.name,
      createdAt: row.createdAt,
      isSystem: row.isSystem,
    );
  }

  Stream<List<domain.Folder>> watchFolders() {
    return (select(folders)
          ..where((f) => f.isSystem.equals(false))
          ..orderBy([(f) => OrderingTerm.desc(f.createdAt)]))
        .watch()
        .map((rows) => rows.map(_folderFromRow).toList());
  }

  Future<int> getOrCreateLikedSongsFolderId() async {
    final existing = await (select(
      folders,
    )..where((f) => f.isSystem.equals(true))).getSingleOrNull();
    if (existing != null) return existing.id;
    return into(folders).insert(
      FoldersCompanion.insert(
        name: 'Liked Songs',
        isSystem: const Value(true),
      ),
    );
  }

  Future<bool> isTrackLiked(String trackId) async {
    final likedId = await getOrCreateLikedSongsFolderId();
    final row = await (select(folderTracks)..where(
          (ft) => ft.folderId.equals(likedId) & ft.trackId.equals(trackId),
        ))
        .getSingleOrNull();
    return row != null;
  }

  Stream<bool> watchIsTrackLiked(String trackId) async* {
    final likedId = await getOrCreateLikedSongsFolderId();
    yield* (select(folderTracks)..where(
          (ft) => ft.folderId.equals(likedId) & ft.trackId.equals(trackId),
        ))
        .watchSingleOrNull()
        .map((row) => row != null);
  }

  Future<List<domain.Track>> getTracksByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final query =
        select(tracks).join([
          leftOuterJoin(
            downloadedTracks,
            downloadedTracks.trackId.equalsExp(tracks.id),
          ),
        ])..where(tracks.id.isIn(ids));
    final rows = await query.get();
    final byId = {
      for (final row in rows)
        row.readTable(tracks).id: _trackFromRows(
          row.readTable(tracks),
          row.readTableOrNull(downloadedTracks),
        ),
    };
    return ids.map((id) => byId[id]).whereType<domain.Track>().toList();
  }

  Future<int> createFolder(String name) {
    return into(folders).insert(FoldersCompanion.insert(name: name));
  }

  Future<void> renameFolder(int id, String name) {
    return (update(
      folders,
    )..where((f) => f.id.equals(id))).write(FoldersCompanion(name: Value(name)));
  }

  Future<void> deleteFolder(int id) {
    return (delete(folders)..where((f) => f.id.equals(id))).go();
  }

  Stream<List<domain.Track>> watchFolderTracks(int folderId) {
    final query =
        select(folderTracks).join([
            innerJoin(tracks, tracks.id.equalsExp(folderTracks.trackId)),
            leftOuterJoin(
              downloadedTracks,
              downloadedTracks.trackId.equalsExp(tracks.id),
            ),
          ])
          ..where(folderTracks.folderId.equals(folderId))
          ..orderBy([OrderingTerm.asc(folderTracks.position)]);

    return query.watch().map(
      (rows) => rows
          .map(
            (row) => _trackFromRows(
              row.readTable(tracks),
              row.readTableOrNull(downloadedTracks),
            ),
          )
          .toList(),
    );
  }

  Future<void> addTrackToFolder(int folderId, domain.Track track) async {
    await upsertTrack(track);
    final positions =
        await (select(
          folderTracks,
        )..where((ft) => ft.folderId.equals(folderId))).map((row) => row.position).get();
    final nextPosition = positions.isEmpty
        ? 0
        : (positions.reduce((a, b) => a > b ? a : b) + 1);
    await into(folderTracks).insertOnConflictUpdate(
      FolderTracksCompanion.insert(
        folderId: folderId,
        trackId: track.id,
        position: nextPosition,
      ),
    );
  }

  Future<void> removeTrackFromFolder(int folderId, String trackId) {
    return (delete(folderTracks)..where(
      (ft) => ft.folderId.equals(folderId) & ft.trackId.equals(trackId),
    )).go();
  }

  Future<void> reorderFolderTracks(
    int folderId,
    List<String> orderedTrackIds,
  ) async {
    await batch((b) {
      for (var i = 0; i < orderedTrackIds.length; i++) {
        b.update(
          folderTracks,
          FolderTracksCompanion(position: Value(i)),
          where: (ft) =>
              ft.folderId.equals(folderId) & ft.trackId.equals(orderedTrackIds[i]),
        );
      }
    });
  }

  Stream<List<domain.Track>> watchDownloadedTracks() {
    final query =
        select(downloadedTracks).join([
            innerJoin(tracks, tracks.id.equalsExp(downloadedTracks.trackId)),
          ])
          ..orderBy([OrderingTerm.desc(downloadedTracks.downloadedAt)]);

    return query.watch().map(
      (rows) => rows
          .map(
            (row) => _trackFromRows(row.readTable(tracks), row.readTable(downloadedTracks)),
          )
          .toList(),
    );
  }

  Future<void> insertDownloadedTrack({
    required String trackId,
    required String filePath,
    required String container,
    required int fileSizeBytes,
  }) {
    return into(downloadedTracks).insertOnConflictUpdate(
      DownloadedTracksCompanion.insert(
        trackId: trackId,
        filePath: filePath,
        container: container,
        fileSizeBytes: fileSizeBytes,
      ),
    );
  }

  Future<void> deleteDownloadedTrack(String trackId) {
    return (delete(
      downloadedTracks,
    )..where((d) => d.trackId.equals(trackId))).go();
  }

  Future<domain.Track?> getDownloadedTrack(String trackId) async {
    final query =
        select(downloadedTracks).join([
          innerJoin(tracks, tracks.id.equalsExp(downloadedTracks.trackId)),
        ])..where(downloadedTracks.trackId.equals(trackId));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return _trackFromRows(row.readTable(tracks), row.readTable(downloadedTracks));
  }

  Stream<int> watchTotalDownloadedBytes() {
    final totalBytes = downloadedTracks.fileSizeBytes.sum();
    final query = selectOnly(downloadedTracks)..addColumns([totalBytes]);
    return query.map((row) => row.read(totalBytes) ?? 0).watchSingle();
  }

  Future<List<String>> getAllDownloadedFilePaths() {
    return select(downloadedTracks).map((row) => row.filePath).get();
  }

  Future<void> deleteAllDownloadedTracks() {
    return delete(downloadedTracks).go();
  }
}
