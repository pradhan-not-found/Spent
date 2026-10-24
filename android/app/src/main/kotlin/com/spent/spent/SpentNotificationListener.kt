package com.spent.spent

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

/**
 * Runs only after the user grants Notification access in Android settings.
 *
 * It looks at notifications from the payment apps the user switched on in Spent and nothing
 * else, keeps only ones that read like a payment, and queues them on the device for the
 * user to review. Nothing is sent anywhere.
 */
class SpentNotificationListener : NotificationListenerService() {
    override fun onNotificationPosted(sbn: StatusBarNotification) {
        if (!PaymentQueue.isWatched(this, sbn.packageName)) return
        val n = sbn.notification ?: return
        // Group summaries repeat the child notifications ("3 new payments").
        if (n.flags and Notification.FLAG_GROUP_SUMMARY != 0) return

        val extras = n.extras
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString().orEmpty()
        val text = (extras.getCharSequence(Notification.EXTRA_BIG_TEXT)
            ?: extras.getCharSequence(Notification.EXTRA_TEXT))?.toString().orEmpty()
        if (!looksLikePayment("$title $text")) return

        PaymentQueue.add(this, "${sbn.key}|${sbn.postTime}", sbn.packageName, title, text, sbn.postTime)
    }

    private fun looksLikePayment(s: String): Boolean = AMOUNT.containsMatchIn(s)

    private companion object {
        // ₹250, Rs. 250, INR 250 — the same shapes lib/payment_parser.dart understands.
        val AMOUNT = Regex("""(₹|\brs\.?|\binr)\s*[0-9]""", RegexOption.IGNORE_CASE)
    }
}
