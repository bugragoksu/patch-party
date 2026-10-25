import 'dart:async';

import 'package:baglanti_agi/app/app.dart';
import 'package:baglanti_agi/app/env.dart';
import 'package:baglanti_agi/app/providers.dart';
import 'package:baglanti_agi/app/theme/tokens.dart';
import 'package:baglanti_agi/core/data/firebase_setup.dart';
import 'package:baglanti_agi/core/observability/error_reporter.dart';
import 'package:baglanti_agi/core/observability/sentry_reporter.dart';
import 'package:baglanti_agi/core/platform/browser.dart';
import 'package:baglanti_agi/core/ui/sticker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

Future<void> main() async {
  Browser.moveHashRouteToPath();
  usePathUrlStrategy(); // /admin, /screen, /j/CODE (hosting rewrites to /)
  WidgetsFlutterBinding.ensureInitialized();
  // Sentry's appRunner wires FlutterError.onError and
  // PlatformDispatcher.onError (ADR-0007); without a DSN errors go to the
  // console.
  await initSentry(() async {
    final reporter = Env.sentryDsn.isEmpty ? DebugReporter() : SentryReporter();
    ErrorWidget.builder = (details) => const _BrokenWidget();
    if (Env.sentryDsn.isEmpty) {
      FlutterError.onError = (details) =>
          unawaited(reporter.report(details.exception, details.stack));
    }
    await initFirebase();
    runApp(
      ProviderScope(
        overrides: [errorReporterProvider.overrideWithValue(reporter)],
        child: const BaglantiApp(),
      ),
    );
  });
}

/// Replaces Flutter's red error box: a quiet sticker, never a stack trace.
class _BrokenWidget extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Sticker(
        outline: Palette.red,
        child: Text(
          'Bu bölüm yüklenemedi. Sayfayı yenile.',
          style: TextStyle(color: Palette.ink),
        ),
      ),
    );
  }
}
