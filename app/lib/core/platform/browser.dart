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

  /// Opens an app route such as `/screen` in a new tab.
  static void openRoute(String route) {
    web.window.open(
      '${web.window.location.origin}$route',
      '_blank',
      'noopener',
    );
  }

  /// Links printed before the switch to path URLs (`/#/j/CODE`) still work:
  /// the fragment route becomes the path before the router starts.
  static void moveHashRouteToPath() {
    try {
      final hash = web.window.location.hash;
      if (hash.startsWith('#/')) {
        web.window.history.replaceState(null, '', hash.substring(1));
      }
    } on Object {
      // Not fatal: the app then opens on its start screen.
    }
  }

  static bool get canFullscreen => web.document.fullscreenEnabled;
  static bool get isFullscreen => web.document.fullscreenElement != null;

  /// Emits on entering or leaving fullscreen (button, Esc or F11).
  static Stream<bool> get fullscreenChanges => web
      .EventStreamProviders
      .fullscreenChangeEvent
      .forTarget(web.document)
      .map((_) => isFullscreen);

  static Future<void> enterFullscreen() async {
    try {
      await web.document.documentElement?.requestFullscreen().toDart;
    } on Object {
      // Refused (no user gesture, or blocked): the button stays visible.
    }
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
