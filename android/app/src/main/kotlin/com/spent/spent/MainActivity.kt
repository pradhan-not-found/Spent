package com.spent.spent

import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

/** Hosts Flutter and answers the `spent/device` channel (see lib/device_apps.dart). */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "spent/device").setMethodCallHandler { call, result ->
            when (call.method) {
                "installedApps" -> {
                    val packages = call.argument<List<String>>("packages") ?: emptyList()
                    result.success(installedIcons(packages))
                }
                "listenerEnabled" -> result.success(listenerEnabled())
                "openListenerSettings" -> {
                    startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                    result.success(null)
                }
                "setWatched" -> {
                    PaymentQueue.setWatched(this, call.argument<List<String>>("packages") ?: emptyList())
                    result.success(null)
                }
                "drain" -> result.success(PaymentQueue.drain(this))
                else -> result.notImplemented()
            }
        }
    }

    /** Launcher icon (PNG) for each of [packages] that is installed; others are skipped. */
    private fun installedIcons(packages: List<String>): Map<String, ByteArray> {
        val out = HashMap<String, ByteArray>()
        for (p in packages) {
            try {
                out[p] = toPng(packageManager.getApplicationIcon(p))
            } catch (_: PackageManager.NameNotFoundException) {
                // Not installed (or not visible — see <queries> in AndroidManifest.xml).
            }
        }
        return out
    }

    private fun listenerEnabled(): Boolean {
        val enabled = Settings.Secure.getString(contentResolver, "enabled_notification_listeners") ?: return false
        return enabled.split(':').any { it.startsWith("$packageName/") }
    }

    private fun toPng(d: Drawable, size: Int = 144): ByteArray {
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        d.setBounds(0, 0, size, size)
        d.draw(Canvas(bitmap))
        return ByteArrayOutputStream().use {
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, it)
            it.toByteArray()
        }
    }
}
