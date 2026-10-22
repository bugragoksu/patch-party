import 'package:baglanti_agi/app/theme/tokens.dart';
import 'package:baglanti_agi/core/ui/feedback.dart';
import 'package:baglanti_agi/features/admin/admin_page.dart' deferred as admin;
import 'package:baglanti_agi/features/play/presentation/camera_test_page.dart';
import 'package:baglanti_agi/features/play/presentation/player_root.dart';
import 'package:baglanti_agi/features/projector/projector_page.dart'
    deferred as projector;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Three surfaces in one app (ADR-0001). Projector and admin are deferred so
/// they never ship in the player's first download (NFR-02).
GoRouter buildRouter() => GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const PlayerRoot()),
    GoRoute(
      path: '/j/:code',
      builder: (context, state) =>
          PlayerRoot(joinCode: state.pathParameters['code']),
    ),
    GoRoute(
      path: '/c/:payload',
      builder: (context, state) =>
          PlayerRoot(scannedPayload: state.pathParameters['payload']),
    ),
    GoRoute(
      path: '/kamera',
      builder: (context, state) => const CameraTestPage(),
    ),
    GoRoute(
      path: '/screen',
      builder: (context, state) => _Deferred(
        load: projector.loadLibrary,
        build: () => projector.ProjectorPage(),
      ),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) =>
          _Deferred(load: admin.loadLibrary, build: () => admin.AdminPage()),
    ),
  ],
  errorBuilder: (context, state) => const PlayerRoot(),
);

class _Deferred extends StatefulWidget {
  const new({required this.load, required this.build});

  final Future<void> Function() load;
  final Widget Function() build;

  @override
  State<_Deferred> createState() => _DeferredState();
}

class _DeferredState extends State<_Deferred> {
  late Future<void> _future = widget.load();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _future,
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
            body: ErrorCard(
              message:
                  'Bu ekran yüklenemedi. Bağlantını kontrol edip tekrar dene.',
              actionLabel: 'Tekrar dene',
              onAction: () => setState(() => _future = widget.load()),
            ),
          );
        }
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Palette.yellow),
            ),
          );
        }
        return widget.build();
      },
    );
  }
}
