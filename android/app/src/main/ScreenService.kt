package com.osman.tawbah

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.IBinder
import android.os.Build
import androidx.core.app.NotificationCompat

class ScreenService : Service() {
    override fun onCreate() {
            super.onCreate()os
                    startForeground(1, createNotification())
                        }

                            private fun createNotification(): Notification {
                                    val channelId = "tawbah_channel"
                                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                                        val channel = NotificationChannel(
                                                                        channelId,
                                                                                        "Tawbah Protection Service",
                                                                                                        NotificationManager.IMPORTANCE_LOW
                                                                                                                    )
                                                                                                                                val manager = getSystemService(NotificationManager::class.java)
                                                                                                                                            manager?.createNotificationChannel(channel)
                                                                                                                                                    }

                                                                                                                                                            return NotificationCompat.Builder(this, channelId)
                                                                                                                                                                        .setContentTitle("تطبيق توبة يعمل في الخلفية")
                                                                                                                                                                                    .setContentText("جاري حماية الشاشة وتصفيتها...")
                                                                                                                                                                                                .setSmallIcon(android.R.drawable.ic_menu_camera)
                                                                                                                                                                                                            .build()
                                                                                                                                                                                                                }

                                                                                                                                                                                                                    override fun onBind(intent: Intent?): IBinder? = null

                                                                                                                                                                                                                        override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
                                                                                                                                                                                                                                return START_STICKY
                                                                                                                                                                                                                                    }
                                                                                                                                                                                                                                    }
