import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

enum _Sound { tap, success, remove, notify }

/// Quiet UI sounds plus matching haptics. Each sound is loaded once into its own
/// low-latency player; failures (no audio device, tests) are swallowed — feedback is a
/// nicety and must never break an action.
abstract final class Sfx {
  /// Mirrors the signed-in user's "Sounds & haptics" setting.
  static bool enabled = true;

  static final _players = <_Sound, AudioPlayer>{};

  static Future<void> _play(_Sound s, {double volume = 1}) async {
    if (!enabled) return;
    try {
      final p = _players[s] ??= await _load(s);
      await p.stop();
      await p.setVolume(volume);
      await p.resume();
    } catch (_) {
      // Ignore: missing audio backend, autoplay restrictions on web, etc.
    }
  }

  static Future<AudioPlayer> _load(_Sound s) async {
    final p = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
    await p.setPlayerMode(PlayerMode.lowLatency);
    await p.setSource(AssetSource('sounds/${s.name}.wav'));
    return p;
  }

  static void _haptic(Future<void> Function() fn) {
    if (enabled) fn().catchError((_) {});
  }

  /// Keypad presses.
  static void tap() {
    _haptic(HapticFeedback.selectionClick);
    _play(_Sound.tap, volume: 0.6);
  }

  /// Switches, tabs, chips: haptic only, since a sound on every toggle gets tiring.
  static void select() => _haptic(HapticFeedback.selectionClick);

  /// Something was saved or added.
  static void success() {
    _haptic(HapticFeedback.lightImpact);
    _play(_Sound.success);
  }

  /// Something was deleted or dismissed.
  static void remove() {
    _haptic(HapticFeedback.mediumImpact);
    _play(_Sound.remove, volume: 0.8);
  }

  /// New payments arrived from a connected app.
  static void notify() {
    _haptic(HapticFeedback.lightImpact);
    _play(_Sound.notify);
  }
}
