package com.osman.tawbah

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.graphics.BitmapFactory
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.view.Gravity
import android.view.WindowManager
import android.widget.ImageView
import androidx.core.app.NotificationCompat

class OverlayService : Service() {
    companion object {
        private var windowManager: WindowManager? = null
        private var imageView: ImageView? = null
        private var isRunning = false

        fun start(context: android.content.Context) {
            if (isRunning) return
            val intent = Intent(context, OverlayService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: android.content.Context) {
            if (!isRunning) return
            val intent = Intent(context, OverlayService::class.java)
            context.stopService(intent)
        }

        fun updateImage(bytes: ByteArray) {
            val bmp = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
            imageView?.post {
                imageView?.setImageBitmap(bmp)
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        
        // إنشاء قناة إشعارات وتشغيل الخدمة في Foreground لمنع قتلها بواسطة النظام
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId = "tawbah_overlay_channel"
            val channel = NotificationChannel(
                channelId,
                "Tawbah Overlay Service",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)

            val notification: Notification = NotificationCompat.Builder(this, channelId)
                .setContentTitle("خدمة التمويه تعمل")
                .setContentText("النافذة العائمة نشطة لحماية الشاشة")
                .setSmallIcon(android.R.drawable.ic_menu_camera)
                .build()
            
            startForeground(101, notification)
        }

        isRunning = true
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        imageView = ImageView(this).apply {
            scaleType = ImageView.ScaleType.FIT_XY
        }

        val layoutFlag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            WindowManager.LayoutParams.TYPE_PHONE
        }

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            layoutFlag,
            // FLAG_NOT_FOCUSABLE و FLAG_NOT_TOUCHABLE لمرور اللمسات
            // FLAG_SECURE لحجب النافذة عن الالتقاط ومنع حلقة التغذية الراجعة
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                    WindowManager.LayoutParams.FLAG_SECURE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        )

        params.gravity = Gravity.CENTER
        windowManager?.addView(imageView, params)
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        isRunning = false
        try {
            if (imageView != null && windowManager != null) {
                windowManager?.removeView(imageView)
            }
        } catch (e: Exception) {}
        imageView = null
        windowManager = null
    }
}
