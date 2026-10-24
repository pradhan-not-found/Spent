package com.spent.spent

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/**
 * On-device hand-off between the notification listener (which may run while Spent is closed)
 * and the Flutter app. Private app storage only; capped so it can't grow without bound.
 */
object PaymentQueue {
    private const val PREFS = "spent_payment_queue"
    private const val WATCHED = "watched"
    private const val QUEUE = "queue"
    private const val MAX = 200

    fun setWatched(ctx: Context, packages: List<String>) {
        prefs(ctx).edit().putStringSet(WATCHED, packages.toSet()).apply()
    }

    fun isWatched(ctx: Context, pkg: String): Boolean =
        prefs(ctx).getStringSet(WATCHED, emptySet())?.contains(pkg) == true

    @Synchronized
    fun add(ctx: Context, key: String, pkg: String, title: String, text: String, postedAt: Long) {
        val queue = read(ctx)
        for (i in 0 until queue.length()) {
            if (queue.getJSONObject(i).optString("key") == key) return
        }
        queue.put(
            JSONObject()
                .put("key", key)
                .put("package", pkg)
                .put("title", title)
                .put("text", text)
                .put("postedAt", postedAt)
        )
        val trimmed = JSONArray()
        for (i in maxOf(0, queue.length() - MAX) until queue.length()) trimmed.put(queue.get(i))
        prefs(ctx).edit().putString(QUEUE, trimmed.toString()).apply()
    }

    /** Returns everything queued and clears the queue. */
    @Synchronized
    fun drain(ctx: Context): List<Map<String, Any>> {
        val queue = read(ctx)
        prefs(ctx).edit().remove(QUEUE).apply()
        return (0 until queue.length()).map { i ->
            val o = queue.getJSONObject(i)
            mapOf(
                "key" to o.getString("key"),
                "package" to o.getString("package"),
                "title" to o.optString("title"),
                "text" to o.optString("text"),
                "postedAt" to o.getLong("postedAt"),
            )
        }
    }

    private fun read(ctx: Context): JSONArray =
        prefs(ctx).getString(QUEUE, null)?.let { JSONArray(it) } ?: JSONArray()

    private fun prefs(ctx: Context) = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}
