import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'brands.dart';
import 'store.dart';

/// Bridge to the Android side (MainActivity / SpentNotificationListener).
///
/// Everything here stays on the device: it checks which payment apps are installed, reads
/// their launcher icons, and collects payment notifications from only the apps the user
/// connected — and only after they grant Notification access in system settings.
abstract final class DeviceApps {
  static const _channel = MethodChannel('spent/device');

  static bool get supported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Launcher icons of installed payment apps, keyed by package. Empty off-Android.
  static final icons = ValueNotifier<Map<String, Uint8List>>({});

  /// Runs a native call, treating any platform failure as "not available" so a missing or
  /// misbehaving Android side can never break the Flutter UI.
  static Future<T> _safe<T>(Future<T> Function() call, T fallback) async {
    if (!supported) return fallback;
    try {
      return await call();
    } on PlatformException {
      return fallback;
    } on MissingPluginException {
      return fallback;
    }
  }

  /// Packages of the payment apps installed on this phone.
  static Future<Set<String>> refreshInstalled() async {
    final res = await _safe<Map<String, Uint8List>?>(
      () => _channel.invokeMapMethod<String, Uint8List>(
        'installedApps',
        {'packages': [for (final a in paymentApps) a.package]},
      ),
      null,
    );
    if (res != null) icons.value = res;
    return icons.value.keys.toSet();
  }

  static Future<bool> listenerEnabled() async =>
      await _safe<bool?>(() => _channel.invokeMethod<bool>('listenerEnabled'), false) ?? false;

  /// Opens Android's Notification access screen so the user can allow (or revoke) Spent.
  static Future<void> openListenerSettings() =>
      _safe<void>(() => _channel.invokeMethod<void>('openListenerSettings'), null);

  /// Tells the listener which packages it may read. Notifications from anything else are
  /// ignored before they're looked at.
  static Future<void> setWatched(Set<String> appIds) {
    final packages = [for (final id in appIds) ?paymentApp(id)?.package];
    return _safe<void>(() => _channel.invokeMethod<void>('setWatched', {'packages': packages}), null);
  }

  /// Takes the notifications queued since the last call (the queue is cleared natively).
  static Future<List<Detected>> drain() async {
    final raw = await _safe<List<Map<Object?, Object?>>?>(() => _channel.invokeListMethod<Map<Object?, Object?>>('drain'), null) ?? [];
    return [
      for (final m in raw)
        if (paymentAppForPackage(m['package'] as String) case final app?)
          Detected(
            id: m['key'] as String,
            app: app.id,
            text: '${m['title'] ?? ''}. ${m['text'] ?? ''}',
            postedAt: m['postedAt'] as int,
          ),
    ];
  }

  /// Opens a specific UPI app's pay screen; falls back to the system UPI chooser.
  static Uri payUri(PaymentApp? app, Map<String, String> params) {
    final base = Uri.parse(app?.payScheme ?? 'upi://pay');
    return base.replace(queryParameters: params);
  }
}
