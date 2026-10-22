import 'package:flutter/foundation.dart';

/// Fixed event names; free text and user input are never logged (SEC-22).
enum AppEvent {
  joinStarted,
  joinRejected,
  joined,
  scanStarted,
  scanRejected,
  requestSent,
  requestAnswered,
  connected,
  cameraDenied,
  manualEntryOpened,
  surfaceFailed,
}

/// The only way app code reports problems (ADR-0007). Sentry is one
/// implementation; tests use [RecordingReporter].
abstract interface class ErrorReporter {
  Future<void> report(Object error, StackTrace? stack, {String? surface});
  void breadcrumb(AppEvent event, {String? detail});
  void setContext({String? surface, String? eventState, String? uidHash});
}

class DebugReporter implements ErrorReporter {
  @override
  Future<void> report(
    Object error,
    StackTrace? stack, {
    String? surface,
  }) async {
    debugPrint('[error] ${surface ?? '-'}: $error\n$stack');
  }

  @override
  void breadcrumb(AppEvent event, {String? detail}) =>
      debugPrint('[event] ${event.name}${detail == null ? '' : ' $detail'}');

  @override
  void setContext({String? surface, String? eventState, String? uidHash}) {}
}

class RecordingReporter implements ErrorReporter {
  final List<Object> errors = [];
  final List<AppEvent> events = [];

  @override
  Future<void> report(
    Object error,
    StackTrace? stack, {
    String? surface,
  }) async => errors.add(error);

  @override
  void breadcrumb(AppEvent event, {String? detail}) => events.add(event);

  @override
  void setContext({String? surface, String? eventState, String? uidHash}) {}
}
