import 'dart:async';
import 'dart:convert';

import 'package:baglanti_agi/app/env.dart';
import 'package:baglanti_agi/core/observability/error_reporter.dart';
import 'package:crypto/crypto.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class SentryReporter implements ErrorReporter {
  @override
  Future<void> report(Object error, StackTrace? stack, {String? surface}) =>
      Sentry.captureException(
        error,
        stackTrace: stack,
        withScope: (scope) async {
          if (surface != null) await scope.setTag('surface', surface);
        },
      );

  @override
  void breadcrumb(AppEvent event, {String? detail}) => unawaited(
    Sentry.addBreadcrumb(
      Breadcrumb(
        category: 'game',
        message: event.name,
        data: detail == null ? null : {'detail': detail},
      ),
    ),
  );

  @override
  void setContext({String? surface, String? eventState, String? uidHash}) {
    unawaited(
      Future<void>.sync(
        () => Sentry.configureScope((scope) async {
          if (surface != null) await scope.setTag('surface', surface);
          if (eventState != null) await scope.setTag('eventState', eventState);
          if (uidHash != null) await scope.setUser(SentryUser(id: uidHash));
        }),
      ),
    );
  }
}

/// Short, non-reversible id for error reports (SEC-22).
String hashUid(String uid) => sha256
    .convert(utf8.encode('${Env.eventId}:$uid'))
    .toString()
    .substring(0, 16);

final _fragment = RegExp('#.*');
final _codePath = RegExp(r'/([jc])/[^/?#\s]+');
final _code = RegExp(r'\b[A-Z2-9]{3}[-.][0-9A-Z]{4,10}\b');
final _transient = RegExp(
  'code=unavailable|code=deadline-exceeded|network-request-failed|'
  'Failed to fetch|Connection failed',
  caseSensitive: false,
);

/// A dropped connection (venue Wi-Fi, a sleeping laptop). The screens already
/// say so and retry; reporting each one would bury real errors.
bool isTransientNetworkError(Object? error) =>
    error != null && _transient.hasMatch('$error');

/// Drops transient network errors and strips join codes and QR payloads
/// (`/j/CODE`, `/c/CODE.TOKEN`, old `#` routes) plus anything shaped like a
/// player code before an event leaves the device.
SentryEvent? scrubEvent(SentryEvent event, Hint hint) {
  if (isTransientNetworkError(event.throwable)) return null;
  String? clean(String? s) => s
      ?.replaceAll(_fragment, '#…')
      .replaceAllMapped(_codePath, (m) => '/${m[1]}/[code]')
      .replaceAll(_code, '[code]');
  final request = event.request;
  return event
    ..request = request == null
        ? null
        : (request
            ..url = clean(request.url)
            ..queryString = null)
    ..breadcrumbs = event.breadcrumbs
        ?.map((b) => b..message = clean(b.message))
        .toList()
    ..transaction = clean(event.transaction)
    ..message = event.message == null
        ? null
        : SentryMessage(clean(event.message!.formatted) ?? '');
}

Future<void> initSentry(AppRunner appRunner) async {
  if (Env.sentryDsn.isEmpty) {
    appRunner();
    return;
  }
  await SentryFlutter.init((o) {
    o
      ..dsn = Env.sentryDsn
      ..environment = Env.name
      ..release = 'baglanti-agi@${Env.version}'
      ..sendDefaultPii = false
      ..tracesSampleRate = 0
      // The package list comes from the 1.3 MB NOTICES asset: a download per
      // reported error, and a second error when it fails to load.
      ..reportPackages = false
      ..beforeSend = scrubEvent;
  }, appRunner: appRunner);
}
