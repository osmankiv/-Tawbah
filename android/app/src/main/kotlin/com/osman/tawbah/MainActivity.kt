package com.osman.tawbah

import android.app.Activity
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.util.DisplayMetrics
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.osman.tawbah/screen"
    private val REQUEST_CODE_SCREEN_CAPTURE = 1000
    private var projectionManager: MediaProjectionManager? = null
    private var mediaProjection: MediaProjection? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var imageReader: ImageReader? = null
    private var pendingResult: MethodChannel.Result? = null

    private var screenWidth = 720
    private var screenHeight = 1280
    private var screenDensity = 1

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        projectionManager = getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager

        val metrics = DisplayMetrics()
        windowManager.defaultDisplay.getMetrics(metrics)
        // تقليل الدقة إلى النصف لتحقيق سرعة فائقة في معالجة الـ TFLite
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
                    captureSingleFrame(result)
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
                mediaProjection = projectionManager?.getMediaProjection(resultCode, data)
                setupVirtualDisplay()
                pendingResult?.success(true)
            } else {
                pendingResult?.success(false)
            }
            pendingResult = null
        }
    }

    private fun setupVirtualDisplay() {
        imageReader = ImageReader.newInstance(screenWidth, screenHeight, PixelFormat.RGBA_8888, 2)
        virtualDisplay = mediaProjection?.createVirtualDisplay(
            "ScreenCapture",
            screenWidth, screenHeight, screenDensity,
            DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
            imageReader?.surface, null, null
        )
    }

    private fun captureSingleFrame(result: MethodChannel.Result) {
        val reader = imageReader
        if (reader == null || mediaProjection == null) {
            result.error("UNINITIALIZED", "MediaProjection or ImageReader is not ready", null)
            return
        }

        val image = reader.acquireLatestImage()
        if (image == null) {
            result.success(null)
            return
        }

        try {
            val planes = image.planes
            val buffer = planes[0].buffer
            val pixelStride = planes[0].pixelStride
            val rowStride = planes[0].rowStride
            val rowPadding = rowStride - pixelStride * screenWidth

            val bitmap = Bitmap.createBitmap(
                screenWidth + rowPadding / pixelStride,
                screenHeight,
                Bitmap.Config.ARGB_8888
            )
            bitmap.copyPixelsFromBuffer(buffer)
            image.close()

            val finalBitmap = Bitmap.createBitmap(bitmap, 0, 0, screenWidth, screenHeight)
            val stream = ByteArrayOutputStream()
            finalBitmap.compress(Bitmap.CompressFormat.JPEG, 70, stream)
            result.success(stream.toByteArray())
        } catch (e: Exception) {
            image.close()
            result.error("CAPTURE_ERROR", e.message, null)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        virtualDisplay?.release()
        mediaProjection?.stop()
        imageReader?.close()
    }
}