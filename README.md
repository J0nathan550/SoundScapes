# SoundScapes

SoundScapes is a Flutter application for searching, streaming, and downloading audio from YouTube. It plays audio-only in the background with full media controls, keeps a local library of liked songs, folders, and downloaded tracks, and runs as a native app on Android, Windows, and Linux from a single codebase.

## Features

- **YouTube search** with live query suggestions (debounced) and no API key required, powered by `youtube_explode_dart`.
- **Audio-only playback** via `just_audio`, `audio_service`, and `audio_session`, with background playback and lock screen / notification media controls.
- **Autoplay / continuous play**: when the queue finishes, SoundScapes automatically searches for and queues related tracks so playback keeps going, similar to a radio mode.
- **Resume on launch**: optionally reopens to the last track you were playing, paused, using a persisted playback snapshot.
- **Downloads for offline listening** (Android): tracks are pulled down with a bundled `yt-dlp` integration, with per-track progress reporting.
- **Local library**: Liked Songs, user-created Folders, and a Downloaded section, all backed by a local SQLite database (`drift`).
- **Streaming cache**: tracks that are played but not explicitly downloaded are cached locally, with a settings screen to view cache size and clear it without touching downloaded tracks.
- **YouTube sign-in**: an in-app WebView login stores an auth cookie to reduce rate-limiting on search and playback.
- **Theming**: light, dark, and system modes, eight built-in color presets, and a custom color option.

## Benefits

- Background, audio-only playback without needing a paid streaming subscription.
- A true offline library: downloaded tracks play without a network connection.
- Local-first data storage (SQLite via `drift`) keeps the library fast and working without any backend server.
- One Dart/Flutter codebase targets mobile and desktop alike.
- Audio-only streaming avoids the bandwidth and battery cost of video playback.

## Tech Stack

| Area | Library |
| --- | --- |
| Framework | Flutter (Dart SDK ^3.13.1) |
| State management | `flutter_riverpod` |
| Local database | `drift`, `drift_flutter` |
| Playback | `just_audio`, `audio_service`, `audio_session`, `rxdart` |
| YouTube data | `youtube_explode_dart` (vendored fork, see below) |
| Downloads | `yt-dlp`, invoked natively on Android via a platform channel |
| Auth | `webview_flutter` (YouTube sign-in), `flutter_secure_storage` |
| Settings | `shared_preferences` |
| Images | `cached_network_image` |

## Project Structure

```
lib/
  core/        Theme, app-wide constants, formatting utilities
  data/        Drift database, tables, and data models
  features/    Screens and Riverpod providers for search, library, player, settings
  services/    Auth, downloads, library repositories, playback, YouTube search
```

## Platform Support

| Platform | Streaming & Library | Downloads |
| --- | --- | --- |
| Android | Yes | Yes (native `yt-dlp` integration) |
| Windows | Yes | Not yet implemented |
| Linux | Yes | Not yet implemented |

## Getting Started

Prerequisites: the Flutter SDK and the toolchain for your target platform (Android SDK, or Visual Studio / build tools for Windows and Linux desktop).

```bash
flutter pub get
flutter run
```

## Vendored `youtube_explode_dart`

`pubspec.yaml` overrides `youtube_explode_dart` to a local copy in `third_party/youtube_explode_dart`. This fixes a `NoSuchMethodError` in the published package (v3.1.0) that occurs when a search result's view count is expressed as multiple text "runs" instead of `simpleText`, such as livestreams showing "N watching". See the comment in `pubspec.yaml` and `third_party/youtube_explode_dart/lib/src/reverse_engineering/pages/search_page.dart` for details.

## Disclaimer

SoundScapes interacts with YouTube for personal, non-commercial use. Users are responsible for complying with YouTube's Terms of Service.
