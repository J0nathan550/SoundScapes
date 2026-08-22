import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:saf_stream/saf_stream.dart';
import 'package:saf_util/saf_util.dart';

import '../../core/theme/theme_presets.dart';
import '../../data/db/app_database.dart';
import '../../data/models/track.dart';
import '../settings/settings_service.dart';

const _backupFileName = 'soundscapes_backup.json';
const _backupMime = 'application/json';

class BackupImportSummary {
  final int folderCount;
  final int trackCount;

  const BackupImportSummary({required this.folderCount, required this.trackCount});
}

/// Exports the app's library (folders, tracks, liked songs) and settings to
/// a user-chosen folder as a single portable JSON file, and can restore from
/// it. This is opt-in and separate from the app's normal on-device storage
/// (SharedPreferences + the local database) — it exists so that data can
/// survive an accidental uninstall by living somewhere outside the app's
/// private storage.
///
/// On Android, the chosen folder is a Storage Access Framework tree Uri
/// (persisted permission, works across app restarts). On desktop it's a
/// plain filesystem path.
class BackupService {
  final SettingsService _settings;
  final AppDatabase _db;
  final _safUtil = SafUtil();
  final _safStream = SafStream();

  Timer? _debounce;
  StreamSubscription<void>? _dbSubscription;

  BackupService(this._settings, this._db) {
    _dbSubscription = _db.tableUpdates().listen((_) => scheduleAutoExport());
  }

  void dispose() {
    _debounce?.cancel();
    _dbSubscription?.cancel();
  }

  bool get isConfigured => _settings.backupFolderRef != null;

  String? get folderDisplayName => _settings.backupFolderDisplayName;

  bool get autoExportEnabled => _settings.autoExportEnabled;

  Future<void> setAutoExportEnabled(bool value) => _settings.setAutoExportEnabled(value);

  /// Opens a native folder picker (SAF on Android) and remembers the chosen
  /// folder. Returns true if the user picked one.
  Future<bool> pickFolder() async {
    if (Platform.isAndroid) {
      final dir = await _safUtil.pickDirectory(
        writePermission: true,
        persistablePermission: true,
      );
      if (dir == null) return false;
      await _settings.setBackupFolder(dir.uri, dir.name);
      return true;
    }
    final path = await FilePicker.getDirectoryPath();
    if (path == null) return false;
    final parts = path.split(Platform.pathSeparator).where((s) => s.isNotEmpty);
    await _settings.setBackupFolder(path, parts.isEmpty ? path : parts.last);
    return true;
  }

  Future<void> clearFolder() => _settings.setBackupFolder(null, null);

  /// Schedules a debounced export so rapid successive changes (e.g. adding
  /// several tracks to a folder) only trigger one write.
  void scheduleAutoExport() {
    if (!autoExportEnabled || !isConfigured) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), () async {
      try {
        await exportNow();
      } catch (_) {
        // Best-effort background sync; explicit "Export now" surfaces errors.
      }
    });
  }

  Future<void> exportNow() async {
    final ref = _settings.backupFolderRef;
    if (ref == null) throw StateError('No backup folder configured');
    final payload = await _buildPayload();
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(payload)));
    if (Platform.isAndroid) {
      await _safStream.writeFileBytes(
        ref,
        _backupFileName,
        _backupMime,
        bytes,
        overwrite: true,
      );
    } else {
      final file = File('$ref${Platform.pathSeparator}$_backupFileName');
      await file.writeAsBytes(bytes, flush: true);
    }
  }

  Future<BackupImportSummary> importNow() async {
    final ref = _settings.backupFolderRef;
    if (ref == null) throw StateError('No backup folder configured');

    final String jsonString;
    if (Platform.isAndroid) {
      final child = await _safUtil.child(ref, [_backupFileName]);
      if (child == null) {
        throw StateError('No backup file found in the chosen folder');
      }
      final bytes = await _safStream.readFileBytes(child.uri);
      jsonString = utf8.decode(bytes);
    } else {
      final file = File('$ref${Platform.pathSeparator}$_backupFileName');
      if (!await file.exists()) {
        throw StateError('No backup file found in the chosen folder');
      }
      jsonString = await file.readAsString();
    }

    final payload = jsonDecode(jsonString) as Map<String, dynamic>;
    return _restore(payload);
  }

  Future<Map<String, dynamic>> _buildPayload() async {
    final folderRows = await _db.select(_db.folders).get();
    final trackRows = await _db.select(_db.tracks).get();
    final folderTrackRows =
        await (_db.select(_db.folderTracks)
              ..orderBy([(ft) => OrderingTerm.asc(ft.position)]))
            .get();

    final trackIdsByFolder = <int, List<String>>{};
    for (final ft in folderTrackRows) {
      trackIdsByFolder.putIfAbsent(ft.folderId, () => []).add(ft.trackId);
    }

    return {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'settings': {
        'themeMode': _settings.themeMode.name,
        'themePreset': _settings.themePreset.name,
        'customThemeColor': _settings.customThemeColor.toARGB32(),
        'autoplayEnabled': _settings.autoplayEnabled,
        'resumePlaybackEnabled': _settings.resumePlaybackEnabled,
      },
      'tracks': {
        for (final t in trackRows)
          t.id: {
            'title': t.title,
            'author': t.author,
            'durationMs': t.durationMs,
            'thumbnailUrl': t.thumbnailUrl,
          },
      },
      'folders': [
        for (final f in folderRows)
          {
            'name': f.name,
            'isSystem': f.isSystem,
            'trackIds': trackIdsByFolder[f.id] ?? const <String>[],
          },
      ],
    };
  }

  Future<BackupImportSummary> _restore(Map<String, dynamic> payload) async {
    final settingsJson = payload['settings'];
    if (settingsJson is Map<String, dynamic>) {
      final themeMode = _enumByName(ThemeMode.values, settingsJson['themeMode']);
      if (themeMode != null) await _settings.setThemeMode(themeMode);

      final themePreset = _enumByName(AppThemePreset.values, settingsJson['themePreset']);
      if (themePreset != null) await _settings.setThemePreset(themePreset);

      final customColor = settingsJson['customThemeColor'];
      if (customColor is int) await _settings.setCustomThemeColor(Color(customColor));

      final autoplay = settingsJson['autoplayEnabled'];
      if (autoplay is bool) await _settings.setAutoplayEnabled(autoplay);

      final resume = settingsJson['resumePlaybackEnabled'];
      if (resume is bool) await _settings.setResumePlaybackEnabled(resume);
    }

    final tracksJson = payload['tracks'];
    final tracksById = <String, Track>{};
    if (tracksJson is Map<String, dynamic>) {
      for (final entry in tracksJson.entries) {
        final map = entry.value;
        if (map is! Map<String, dynamic>) continue;
        final title = map['title'];
        final author = map['author'];
        final durationMs = map['durationMs'];
        final thumbnailUrl = map['thumbnailUrl'];
        if (title is! String ||
            author is! String ||
            durationMs is! int ||
            thumbnailUrl is! String) {
          continue;
        }
        tracksById[entry.key] = Track(
          id: entry.key,
          title: title,
          author: author,
          duration: Duration(milliseconds: durationMs),
          thumbnailUrl: thumbnailUrl,
        );
      }
    }

    final foldersJson = payload['folders'];
    final existingFolders = await _db.select(_db.folders).get();

    var folderCount = 0;
    var trackCount = 0;
    if (foldersJson is List) {
      for (final raw in foldersJson) {
        if (raw is! Map<String, dynamic>) continue;
        final name = raw['name'];
        if (name is! String) continue;
        final isSystem = raw['isSystem'] == true;
        final trackIds = raw['trackIds'];

        final int folderId;
        if (isSystem) {
          folderId = await _db.getOrCreateLikedSongsFolderId();
        } else {
          FolderRow? match;
          for (final f in existingFolders) {
            if (!f.isSystem && f.name == name) {
              match = f;
              break;
            }
          }
          folderId = match?.id ?? await _db.createFolder(name);
        }
        folderCount++;

        if (trackIds is List) {
          for (final trackId in trackIds) {
            final track = tracksById[trackId];
            if (track == null) continue;
            await _db.addTrackToFolder(folderId, track);
            trackCount++;
          }
        }
      }
    }

    return BackupImportSummary(folderCount: folderCount, trackCount: trackCount);
  }

  T? _enumByName<T extends Enum>(List<T> values, Object? name) {
    if (name is! String) return null;
    for (final v in values) {
      if (v.name == name) return v;
    }
    return null;
  }
}
