import '../../data/db/app_database.dart';
import '../../data/models/folder.dart';
import '../../data/models/track.dart';

class FolderRepository {
  final AppDatabase _db;

  FolderRepository(this._db);

  Stream<List<Folder>> watchFolders() => _db.watchFolders();

  Stream<List<Track>> watchFolderTracks(int folderId) =>
      _db.watchFolderTracks(folderId);

  Future<int> createFolder(String name) => _db.createFolder(name);

  Future<void> renameFolder(int id, String name) => _db.renameFolder(id, name);

  Future<void> deleteFolder(int id) => _db.deleteFolder(id);

  Future<void> addTrackToFolder(int folderId, Track track) =>
      _db.addTrackToFolder(folderId, track);

  Future<void> removeTrackFromFolder(int folderId, String trackId) =>
      _db.removeTrackFromFolder(folderId, trackId);

  Future<void> reorderTracks(int folderId, List<String> orderedTrackIds) =>
      _db.reorderFolderTracks(folderId, orderedTrackIds);

  Future<int> getOrCreateLikedSongsFolderId() =>
      _db.getOrCreateLikedSongsFolderId();

  Stream<bool> watchIsLiked(String trackId) => _db.watchIsTrackLiked(trackId);

  Future<void> toggleLiked(Track track) async {
    final likedId = await _db.getOrCreateLikedSongsFolderId();
    final liked = await _db.isTrackLiked(track.id);
    if (liked) {
      await _db.removeTrackFromFolder(likedId, track.id);
    } else {
      await _db.addTrackToFolder(likedId, track);
    }
  }
}
