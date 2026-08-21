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
      orElse: () => AppThemePreset.violet,
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
}
