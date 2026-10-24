import 'package:baglanti_agi/app/router.dart';
import 'package:baglanti_agi/app/theme/theme.dart';
import 'package:baglanti_agi/app/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BaglantiApp extends StatefulWidget {
  const new({super.key});

  @override
  State<BaglantiApp> createState() => _BaglantiAppState();
}

class _BaglantiAppState extends State<BaglantiApp> {
  late final GoRouter _router = buildRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Patch Party',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      routerConfig: _router,
      builder: (context, child) {
        // Text may scale, but not so far that the one-screen layouts break.
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(maxScaleFactor: 1.6),
          ),
          child: ColoredBox(
            color: Palette.asphalt,
            child: child ?? const SizedBox(),
          ),
        );
      },
    );
  }
}
