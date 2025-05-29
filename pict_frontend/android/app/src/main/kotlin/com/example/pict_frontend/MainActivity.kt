package com.example.pict_frontend

import android.content.Context
import android.media.AudioManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Handler
import android.os.Looper

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.pict.recycler/audio").setMethodCallHandler { call, result ->
            if (call.method == "setSpeakerphoneOn") {
                val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                val handler = Handler(Looper.getMainLooper())

                // Attempt to set speakerphone multiple times
                for (i in 0..2) { // Try 3 times
                    handler.postDelayed({ // Use Handler to post to main thread with delay
                        try {
                            audioManager.mode = AudioManager.MODE_NORMAL
                            audioManager.isSpeakerphoneOn = true
                            // Log.d("Speakerphone", "Attempt #$i: Mode ${audioManager.mode}, Speaker ${audioManager.isSpeakerphoneOn}"); // Optional debug log
                        } catch (e: Exception) {
                            // Log error if setting fails
                            // Log.e("Speakerphone", "Attempt #$i failed: ${e.message}"); // Optional debug log
                        }
                    }, (i * 200).toLong()) // Increase delay with each attempt
                }

                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }
}
