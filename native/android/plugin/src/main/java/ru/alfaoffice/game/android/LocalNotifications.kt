package ru.alfaoffice.game.android

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

/**
 * Local notifications planned by the game: reminders to check in, draw announcements, nudges.
 * Each one is an inexact AlarmManager alarm (no exact-alarm permission needed) that fires
 * [NotificationReceiver]. Ids of pending alarms are kept in SharedPreferences so they can all be
 * cancelled when the game replaces its plan. Alarms do not survive a reboot; the game reschedules
 * them on the next launch.
 */
object LocalNotifications {
    private const val TAG = "LocalNotifications"
    private const val CHANNEL_ID = "office_game_reminders"
    private const val PREFS = "office_game_notifications"
    private const val KEY_IDS = "scheduled_ids"
    const val EXTRA_ID = "id"
    const val EXTRA_TITLE = "title"
    const val EXTRA_BODY = "body"

    fun schedule(context: Context, id: Int, title: String, body: String, delaySeconds: Int) {
        val alarms = context.getSystemService(AlarmManager::class.java) ?: return
        val at = System.currentTimeMillis() + delaySeconds.coerceAtLeast(0) * 1000L
        alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pendingIntent(context, id, title, body))
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val ids = prefs.getStringSet(KEY_IDS, emptySet()).orEmpty() + id.toString()
        prefs.edit().putStringSet(KEY_IDS, ids).apply()
    }

    fun cancelAll(context: Context) {
        val alarms = context.getSystemService(AlarmManager::class.java) ?: return
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        for (id in prefs.getStringSet(KEY_IDS, emptySet()).orEmpty()) {
            id.toIntOrNull()?.let { alarms.cancel(pendingIntent(context, it, "", "")) }
        }
        prefs.edit().remove(KEY_IDS).apply()
    }

    /** The request code is the id, so a new alarm with the same id replaces the old one. */
    private fun pendingIntent(context: Context, id: Int, title: String, body: String): PendingIntent {
        val intent = Intent(context, NotificationReceiver::class.java)
            .putExtra(EXTRA_ID, id)
            .putExtra(EXTRA_TITLE, title)
            .putExtra(EXTRA_BODY, body)
        return PendingIntent.getBroadcast(
            context, id, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    fun show(context: Context, id: Int, title: String, body: String) {
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && manager.getNotificationChannel(CHANNEL_ID) == null) {
            val channel = NotificationChannel(CHANNEL_ID, "Альфа Офис", NotificationManager.IMPORTANCE_DEFAULT)
            channel.description = "Напоминания о серии, розыгрыши и новости игры"
            manager.createNotificationChannel(channel)
        }
        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)?.let {
            PendingIntent.getActivity(context, 0, it, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        }
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
        }
        val notification = builder
            .setSmallIcon(context.applicationInfo.icon)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(Notification.BigTextStyle().bigText(body))
            .setAutoCancel(true)
            .setContentIntent(launch)
            .build()
        try {
            manager.notify(id, notification)
        } catch (error: SecurityException) {
            Log.w(TAG, "Notifications are not allowed", error)
        }
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val ids = prefs.getStringSet(KEY_IDS, emptySet()).orEmpty() - id.toString()
        prefs.edit().putStringSet(KEY_IDS, ids).apply()
    }
}

/** Fired by the alarm; posts the notification even when the game is not running. */
class NotificationReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        LocalNotifications.show(
            context,
            intent.getIntExtra(LocalNotifications.EXTRA_ID, 0),
            intent.getStringExtra(LocalNotifications.EXTRA_TITLE).orEmpty(),
            intent.getStringExtra(LocalNotifications.EXTRA_BODY).orEmpty(),
        )
    }
}
