# SoundScapes

SoundScapes is a Flutter application for searching, streaming, and downloading audio from YouTube. It plays audio-only in the background with full media controls, keeps a local library of liked songs, folders, and downloaded tracks, and runs as a native app on Android and Windows.

## Features

- **YouTube search** with live query suggestions (debounced) and no API key required, powered by `youtube_explode_dart`.
- **Audio-only playback** via `just_audio`, `audio_service`, and `audio_session`, with background playback and lock screen / notification media controls.
- **Autoplay / continuous play**: when the queue finishes, SoundScapes automatically searches for and queues related tracks so playback keeps going, similar to a radio mode.
- **Resume on launch**: optionally reopens to the last track you were playing, paused, using a persisted playback snapshot.
- **Downloads for offline listening**: tracks are pulled down with a `yt-dlp` integration, with per-track progress reporting — bundled on Android, fetched on first use on Windows.
- **Local library**: Liked Songs, user-created Folders, and a Downloaded section, all backed by a local SQLite database (`drift`).
- **Streaming cache**: tracks that are played but not explicitly downloaded are cached locally, with a settings screen to view cache size and clear it without touching downloaded tracks.
- **YouTube sign-in**: an in-app WebView login stores an auth cookie to reduce rate-limiting on search and playback.
- **Theming**: light, dark, and system modes, eight built-in color presets, and a custom color option.
