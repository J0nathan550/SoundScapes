package com.j0nathan550.soundscapes

import android.app.Application
import android.util.Log
import com.yausername.ffmpeg.FFmpeg
import com.yausername.youtubedl_android.YoutubeDL
import kotlin.concurrent.thread

class SoundscapesApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        // Unpacks the bundled Python/yt-dlp/ffmpeg binaries on first run, which can take a
        // moment — done off the main thread so it doesn't risk an ANR on cold start.
        thread {
            try {
                YoutubeDL.init(this)
                FFmpeg.init(this)
            } catch (e: Exception) {
                Log.e("SoundscapesApp", "Failed to initialize yt-dlp/ffmpeg", e)
                return@thread
            }
            // The bundled yt-dlp binary is a fixed snapshot from whenever this
            // library version was published — it goes stale fast against
            // YouTube's frequently-changing anti-bot measures (PO Tokens,
            // SABR streaming). Self-update against yt-dlp's own GitHub
            // releases, same as running `yt-dlp -U`. Best-effort: a failure
            // here (e.g. offline) just means downloads keep using whatever
            // version is already unpacked.
            try {
                YoutubeDL.getInstance().updateYoutubeDL(this)
            } catch (e: Exception) {
                Log.w("SoundscapesApp", "yt-dlp self-update failed, continuing with bundled version", e)
            }
        }
    }
}
