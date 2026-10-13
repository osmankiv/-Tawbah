package com.osman.tawbah

import android.app.Activity
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.util.DisplayMetrics
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.osman.tawbah/screen"
    private val REQUEST_CODE_SCREEN_CAPTURE = 1000
    private var projectionManager: MediaProjectionManager? = null
    private var pendingResult: MethodChannel.Result? = null

    private var screenWidth = 720
    private var screenHeight = 1280
    private var screenDensity = 1

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        projectionManager = getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager

        val metrics = DisplayMetrics()
        windowManager.defaultDisplay.getMetrics(metrics)
        screenWidth = metrics.widthPixels / 2
        screenHeight = metrics.heightPixels / 2
        screenDensity = metrics.densityDpi

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestScreenCapture" -> {
                    pendingResult = result
                    val intent = projectionManager?.createScreenCaptureIntent()
                    startActivityForResult(intent, REQUEST_CODE_SCREEN_CAPTURE)
                }
                "captureScreen" -> {
                    val bytes = ScreenService.captureFrame()
                    result.success(bytes)
                }
                "startOverlay" -> {
                    OverlayService.start(this)
                    result.success(true)
                }
                "stopOverlay" -> {
                    OverlayService.stop(this)
                    result.success(true)
                }
                "updateOverlay" -> {
                    val bytes = call.argument<ByteArray>("bytes")
                    if (bytes != null) {
                        OverlayService.updateImage(bytes)
                    }
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE_SCREEN_CAPTURE) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val serviceIntent = Intent(this, ScreenService::class.java)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    startForegroundService(serviceIntent)
                } else {
                    startService(serviceIntent)
                }

                val projection = projectionManager?.getMediaProjection(resultCode, data)
                if (projection != null) {
                    ScreenService.setupVirtualDisplay(projection, screenWidth, screenHeight, screenDensity)
                }
                pendingResult?.success(true)
            } else {
                pendingResult?.success(false)
            }
            pendingResult = null
        }
    }
}
