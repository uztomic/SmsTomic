package com.example.smstomic

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

/// SMS ommaviy yuborilayotganda doimiy bildirishnoma ko'rsatuvchi va
/// jarayonni ilova fonga o'tsa ham (RAM'dan tozalanmagunicha) davom
/// ettirishga yordam beruvchi foreground service.
class SmsSendingService : Service() {
    companion object {
        const val CHANNEL_ID = "sms_sending_channel"
        const val NOTIFICATION_ID = 5001
        const val ACTION_STOP = "com.example.smstomic.action.STOP"
        const val EXTRA_SENT = "sent"
        const val EXTRA_TOTAL = "total"
        const val EXTRA_DONE = "done"
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        createChannelIfNeeded()

        if (intent?.action == ACTION_STOP) {
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            return START_NOT_STICKY
        }

        val sent = intent?.getIntExtra(EXTRA_SENT, 0) ?: 0
        val total = intent?.getIntExtra(EXTRA_TOTAL, 0) ?: 0
        val done = intent?.getBooleanExtra(EXTRA_DONE, false) ?: false
        val notification = buildNotification(sent, total, done)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(NOTIFICATION_ID, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }

        if (done) {
            stopForeground(STOP_FOREGROUND_DETACH)
            stopSelf()
        }

        return START_NOT_STICKY
    }

    private fun buildNotification(sent: Int, total: Int, done: Boolean): Notification {
        val title = if (done) "SMS yuborish yakunlandi" else "SMS yuborilmoqda"
        val text = "$sent / $total yuborildi"
        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(text)
            .setSmallIcon(android.R.drawable.stat_sys_upload)
            .setOnlyAlertOnce(true)
            .setOngoing(!done)
            .setPriority(NotificationCompat.PRIORITY_LOW)

        if (!done) {
            builder.setProgress(total, sent, false)
        }

        return builder.build()
    }

    private fun createChannelIfNeeded() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java)
            if (manager.getNotificationChannel(CHANNEL_ID) == null) {
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    "SMS yuborish",
                    NotificationManager.IMPORTANCE_LOW,
                )
                manager.createNotificationChannel(channel)
            }
        }
    }
}
