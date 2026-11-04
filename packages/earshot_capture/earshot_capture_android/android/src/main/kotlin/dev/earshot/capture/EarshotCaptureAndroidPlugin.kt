package dev.earshot.capture

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import io.flutter.embedding.engine.plugins.FlutterPlugin

/** The Android host side of earshot_capture. */
class EarshotCaptureAndroidPlugin :
    FlutterPlugin,
    EarshotCaptureHostApi {
    private var context: Context? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        EarshotCaptureHostApi.setUp(binding.binaryMessenger, this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        EarshotCaptureHostApi.setUp(binding.binaryMessenger, null)
        context = null
    }

    /**
     * Reads RECORD_AUDIO without prompting. Android cannot tell "never asked"
     * apart from "denied" without an Activity, so this is granted or denied.
     */
    override fun microphonePermissionStatus(): PermissionStatusMessage {
        val ctx = checkNotNull(context) { "earshot_capture is not attached to an engine" }
        // minSdk is 24, so Context.checkSelfPermission (API 23) needs no androidx.
        val result = ctx.checkSelfPermission(Manifest.permission.RECORD_AUDIO)
        return if (result == PackageManager.PERMISSION_GRANTED) {
            PermissionStatusMessage.GRANTED
        } else {
            PermissionStatusMessage.DENIED
        }
    }
}
