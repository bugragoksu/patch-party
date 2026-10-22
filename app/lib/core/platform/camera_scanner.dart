import 'dart:async';
import 'dart:js_interop';
import 'dart:ui';

/// Outcome of trying to open the camera.
enum CameraError { denied, noCamera, failed }

/// The camera lives outside Flutter (web/scanner.js, ADR-0006). Flutter only
/// reserves the viewfinder rectangle and tells the scanner where it is.
abstract interface class CameraScanner {
  Future<void> start(
    Rect rect, {
    required void Function(String) onCode,
    required void Function(CameraError) onError,
  });
  void place(Rect rect);
  void stop();
  void prefetch();
}

@JS('bagScanner')
external _BagScanner? get _bagScanner;

extension type _BagScanner._(JSObject _) implements JSObject {
  external JSPromise<JSAny?> start(
    num x,
    num y,
    num w,
    num h,
    JSFunction onResult,
    JSFunction onError,
  );
  external void place(num x, num y, num w, num h);
  external void stop();
  external void prefetch();
}

class WebCameraScanner implements CameraScanner {
  @override
  Future<void> start(
    Rect rect, {
    required void Function(String) onCode,
    required void Function(CameraError) onError,
  }) async {
    final scanner = _bagScanner;
    if (scanner == null) {
      onError(CameraError.failed);
      return;
    }
    await scanner
        .start(
          rect.left,
          rect.top,
          rect.width,
          rect.height,
          ((JSString text) => onCode(text.toDart)).toJS,
          ((JSString reason) => onError(switch (reason.toDart) {
            'denied' => CameraError.denied,
            'no-camera' => CameraError.noCamera,
            _ => CameraError.failed,
          })).toJS,
        )
        .toDart;
  }

  @override
  void place(Rect rect) =>
      _bagScanner?.place(rect.left, rect.top, rect.width, rect.height);

  @override
  void stop() => _bagScanner?.stop();

  @override
  void prefetch() => _bagScanner?.prefetch();
}

/// Test and non-web fallback: never opens a camera.
class NoCameraScanner implements CameraScanner {
  @override
  Future<void> start(
    Rect rect, {
    required void Function(String) onCode,
    required void Function(CameraError) onError,
  }) async => onError(CameraError.noCamera);

  @override
  void place(Rect rect) {}

  @override
  void stop() {}

  @override
  void prefetch() {}
}
