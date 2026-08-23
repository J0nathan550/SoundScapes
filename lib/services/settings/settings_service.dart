import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/theme_presets.dart';
import '../../data/models/playback_snapshot.dart';

class SettingsService {
  static const _themeModeKey = 'settings.themeMode';
  static const _themePresetKey = 'settings.themePreset';
  static const _customThemeColorKey = 'settings.customThemeColor';
  static const _autoplayKey = 'settings.autoplayEnabled';
  static const _resumePlaybackKey = 'settings.resumePlaybackEnabled';
  static const _playbackSnapshotKey = 'settings.playbackSnapshot';
  static const _lastSearchQueryKey = 'settings.lastSearchQuery';
  static const _lastSearchTabIndexKey = 'settings.lastSearchTabIndex';
  static const _backupFolderRefKey = 'settings.backupFolderRef';
  static const _backupFolderNameKey = 'settings.backupFolderName';
  static const _autoExportEnabledKey = 'settings.autoExportEnabled';
  static const _devModeEnabledKey = 'settings.devModeEnabled';
  static const _dismissedUpdateVersionKey = 'settings.dismissedUpdateVersion';
  static const _dismissedUpdateAtKey = 'settings.dismissedUpdateAt';
  static const _windowsVolumeKey = 'settings.windowsVolume';

  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  ThemeMode get themeMode {
    final value = _prefs.getString(_themeModeKey);
    return ThemeMode.values.firstWhere(
      (m) => m.name == value,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) => _prefs.setString(_themeModeKey, mode.name);

  AppThemePreset get themePreset {
    final value = _prefs.getString(_themePresetKey);
    return AppThemePreset.values.firstWhere(
      (p) => p.name == value,
      orElse: () => AppThemePreset.monochrome,
    );
  }

  Future<void> setThemePreset(AppThemePreset preset) =>
      _prefs.setString(_themePresetKey, preset.name);

  Color get customThemeColor {
    final value = _prefs.getInt(_customThemeColorKey);
    return value != null ? Color(value) : const Color(0xFF7C4DFF);
  }

  Future<void> setCustomThemeColor(Color color) =>
      _prefs.setInt(_customThemeColorKey, color.toARGB32());

  bool get autoplayEnabled => _prefs.getBool(_autoplayKey) ?? true;

  Future<void> setAutoplayEnabled(bool value) => _prefs.setBool(_autoplayKey, value);

  bool get resumePlaybackEnabled => _prefs.getBool(_resumePlaybackKey) ?? true;

  Future<void> setResumePlaybackEnabled(bool value) =>
      _prefs.setBool(_resumePlaybackKey, value);

  PlaybackSnapshot? get playbackSnapshot {
    final raw = _prefs.getString(_playbackSnapshotKey);
    if (raw == null) return null;
    try {
      return PlaybackSnapshot.fromJson(json.decode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> savePlaybackSnapshot(PlaybackSnapshot snapshot) =>
      _prefs.setString(_playbackSnapshotKey, json.encode(snapshot.toJson()));

  String get lastSearchQuery => _prefs.getString(_lastSearchQueryKey) ?? '';

  Future<void> setLastSearchQuery(String query) =>
      _prefs.setString(_lastSearchQueryKey, query);

  int get lastSearchTabIndex => _prefs.getInt(_lastSearchTabIndexKey) ?? 0;

  Future<void> setLastSearchTabIndex(int index) =>
      _prefs.setInt(_lastSearchTabIndexKey, index);

  /// On Android this is a persisted SAF tree URI; on desktop it's a plain
  /// filesystem path. Either way it's opaque to callers outside
  /// [BackupService].
  String? get backupFolderRef => _prefs.getString(_backupFolderRefKey);

  String? get backupFolderDisplayName => _prefs.getString(_backupFolderNameKey);

  Future<void> setBackupFolder(String? ref, String? displayName) async {
    if (ref == null) {
      await _prefs.remove(_backupFolderRefKey);
      await _prefs.remove(_backupFolderNameKey);
      return;
    }
    await _prefs.setString(_backupFolderRefKey, ref);
    await _prefs.setString(_backupFolderNameKey, displayName ?? ref);
  }

  bool get autoExportEnabled => _prefs.getBool(_autoExportEnabledKey) ?? false;

  Future<void> setAutoExportEnabled(bool value) =>
      _prefs.setBool(_autoExportEnabledKey, value);

  bool get devModeEnabled => _prefs.getBool(_devModeEnabledKey) ?? false;

  Future<void> setDevModeEnabled(bool value) =>
      _prefs.setBool(_devModeEnabledKey, value);

  /// The release version (e.g. "1.0.42") the user last dismissed an
  /// "update available" prompt for, and when. Used to avoid re-prompting for
  /// the same version more than once a day.
  String? get dismissedUpdateVersion => _prefs.getString(_dismissedUpdateVersionKey);

  DateTime? get dismissedUpdateAt {
    final millis = _prefs.getInt(_dismissedUpdateAtKey);
    return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<void> setDismissedUpdate(String version, DateTime at) async {
    await _prefs.setString(_dismissedUpdateVersionKey, version);
    await _prefs.setInt(_dismissedUpdateAtKey, at.millisecondsSinceEpoch);
  }

  /// Windows only — there's no hardware volume control on desktop, so the
  /// app-level volume set via the Now Playing screen's slider is persisted
  /// here and restored on launch.
  double get windowsVolume => _prefs.getDouble(_windowsVolumeKey) ?? 1.0;

  Future<void> setWindowsVolume(double value) =>
      _prefs.setDouble(_windowsVolumeKey, value);
}
