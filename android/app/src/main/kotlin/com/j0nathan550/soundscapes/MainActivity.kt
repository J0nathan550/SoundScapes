package com.j0nathan550.soundscapes

import android.content.Intent
import androidx.core.content.FileProvider
import com.ryanheise.audioservice.AudioServiceActivity
import com.yausername.youtubedl_android.YoutubeDL
import com.yausername.youtubedl_android.YoutubeDLRequest
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import kotlin.concurrent.thread

private const val CHANNEL_NAME = "soundscapes/ytdlp"
private const val UPDATER_CHANNEL_NAME = "soundscapes/updater"

class MainActivity : AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "downloadAudio" -> handleDownloadAudio(call, channel, result)
                else -> result.notImplemented()
            }
        }

        val updaterChannel =
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, UPDATER_CHANNEL_NAME)
        updaterChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "installApk" -> handleInstallApk(call, result)
                else -> result.notImplemented()
            }
        }
    }

    private fun handleInstallApk(
        call: io.flutter.plugin.common.MethodCall,
        result: MethodChannel.Result,
    ) {
        val filePath = call.argument<String>("filePath")
        if (filePath.isNullOrBlank()) {
            result.error("bad_args", "filePath is required", null)
            return
        }
        try {
            val apkFile = File(filePath)
            val apkUri = FileProvider.getUriForFile(this, "$packageName.fileprovider", apkFile)
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(apkUri, "application/vnd.android.package-archive")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            startActivity(intent)
            result.success(null)
        } catch (e: Exception) {
            result.error("install_error", e.message, null)
        }
    }

    private fun handleDownloadAudio(
        call: io.flutter.plugin.common.MethodCall,
        channel: MethodChannel,
        result: MethodChannel.Result,
    ) {
        val videoId = call.argument<String>("videoId")
        val outputPathNoExt = call.argument<String>("outputPathNoExt")
        if (videoId.isNullOrBlank() || outputPathNoExt.isNullOrBlank()) {
            result.error("bad_args", "videoId and outputPathNoExt are required", null)
            return
        }

        thread {
            try {
                // No -x/--audio-format: that requires yt-dlp to shell out to the
                // bundled ffmpeg for remuxing, and youtubedl-android's bundled
                // ffmpeg/ffprobe binaries aren't built for 16KB-page-size devices
                // (crashes with "program alignment (4096) cannot be smaller than
                // system page size"). Downloading the best audio-only format
                // directly, with no post-processing, avoids invoking ffmpeg at all
                // — just_audio/ExoPlayer plays the resulting webm/m4a/opus file
                // natively either way.
                val request = YoutubeDLRequest("https://www.youtube.com/watch?v=$videoId")
                request.addOption("-f", "bestaudio")
                request.addOption("-o", "$outputPathNoExt.%(ext)s")
                // YouTube increasingly forces "SABR streaming" on the default web
                // client, which withholds direct-URL formats without a PO Token
                // (this app's bundled yt-dlp has no PO Token provider) — falls back
                // to android/tv clients, which don't require one for most videos.
                // See https://github.com/yt-dlp/yt-dlp/issues/12482.
                request.addOption("--extractor-args", "youtube:player_client=default,android,tv")

                YoutubeDL.getInstance().execute(request, videoId) { progress, _, _ ->
                    runOnUiThread {
                        channel.invokeMethod(
                            "progress",
                            mapOf("videoId" to videoId, "percent" to progress.toDouble()),
                        )
                    }
                }

                val outputFile = findOutputFile(outputPathNoExt)
                runOnUiThread {
                    if (outputFile != null) {
                        result.success(
                            mapOf(
                                "filePath" to outputFile.absolutePath,
                                "fileSizeBytes" to outputFile.length(),
                            ),
                        )
                    } else {
                        result.error("no_output", "yt-dlp produced no output file", null)
                    }
                }
            } catch (e: Exception) {
                runOnUiThread { result.error("ytdlp_error", e.message, null) }
            }
        }
    }

    private fun findOutputFile(outputPathNoExt: String): File? {
        val target = File(outputPathNoExt)
        val dir = target.parentFile ?: return null
        val prefix = "${target.name}."
        return dir.listFiles { f -> f.isFile && f.name.startsWith(prefix) }?.firstOrNull()
    }
}
