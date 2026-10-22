import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Small browser facts the app reacts to. Kept behind functions so widgets
/// stay testable off the web.
abstract final class Browser {
  static String get origin => web.window.location.origin;

  /// Instagram, Facebook, WhatsApp and LinkedIn webviews break camera and
  /// storage in various ways (NFR-10).
  static bool get isInAppBrowser {
    final ua = web.window.navigator.userAgent;
    return RegExp('Instagram|FBAN|FBAV|WhatsApp|LinkedInApp').hasMatch(ua);
  }

  static String? read(String key) {
    try {
      return web.window.localStorage.getItem(key);
    } on Object {
      return null;
    }
  }

  static void write(String key, String value) {
    try {
      web.window.localStorage.setItem(key, value);
    } on Object {
      // Private mode or blocked storage: the game still works without it.
    }
  }
}

/// Keeps the screen on while the QR is shown; silently does nothing where
/// the Wake Lock API is missing.
class WakeLock {
  web.WakeLockSentinel? _sentinel;

  Future<void> acquire() async {
    try {
      _sentinel ??= await web.window.navigator.wakeLock
          .request('screen')
          .toDart;
    } on Object {
      _sentinel = null;
    }
  }

  Future<void> release() async {
    final s = _sentinel;
    _sentinel = null;
    try {
      await s?.release().toDart;
    } on Object {
      // Already released by the browser.
    }
  }
}
