import 'dart:async';

import 'package:baglanti_agi/app/providers.dart';
import 'package:baglanti_agi/app/theme/tokens.dart';
import 'package:baglanti_agi/core/domain/token.dart';
import 'package:baglanti_agi/core/platform/browser.dart';
import 'package:baglanti_agi/core/platform/camera_scanner.dart';
import 'package:baglanti_agi/core/ui/buttons.dart';
import 'package:baglanti_agi/core/ui/sticker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Spike S2 (ADR-0006): checks the camera layer on real phones without the
/// backend. One phone shows a rotating QR, the other scans it and reports
/// how long the first read took. Route: /#/kamera
class CameraTestPage extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<CameraTestPage> createState() => _CameraTestPageState();
}

class _CameraTestPageState extends ConsumerState<CameraTestPage> {
  bool _scanning = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Kamera testi',
                    style: TextStyles.display.copyWith(
                      fontSize: 26,
                      color: Palette.paper,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Bir telefonda QR göster, diğerinde tara.',
                    style: TextStyles.ui.copyWith(color: Palette.textMuted),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _scanning ? const _ScanProbe() : const _QrProbe(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DockButton(
                          label: 'QR göster',
                          icon: Icons.qr_code_2,
                          active: !_scanning,
                          onPressed: () => setState(() => _scanning = false),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DockButton(
                          label: 'Tara',
                          icon: Icons.qr_code_scanner,
                          active: _scanning,
                          onPressed: () => setState(() => _scanning = true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QrProbe extends ConsumerWidget {
  const new();

  static const _seed = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now =
        ref.watch(nowProvider).value ?? DateTime.now().millisecondsSinceEpoch;
    final token = tokenFor(_seed, 'camera-test', windowOf(now, 30));
    return Center(
      child: Sticker(
        shadow: Palette.yellow,
        tiltDegrees: -2,
        child: SizedBox(
          width: 260,
          child: QrImageView(
            data: qrPayload(Browser.origin, 'TST', token.qr),
            padding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }
}

class _ScanProbe extends ConsumerStatefulWidget {
  const new();

  @override
  ConsumerState<_ScanProbe> createState() => _ScanProbeState();
}

class _ScanProbeState extends ConsumerState<_ScanProbe> {
  final GlobalKey<State<StatefulWidget>> _box = GlobalKey();
  late final CameraScanner _scanner = ref.read(cameraScannerProvider);
  final _watch = Stopwatch();
  String _status = 'Kamera açılıyor…';
  int _reads = 0;
  int? _firstReadMs;
  String? _last;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_start()));
  }

  @override
  void dispose() {
    _scanner.stop();
    super.dispose();
  }

  Future<void> _start() async {
    final box = _box.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    _watch.start();
    await _scanner.start(
      (box.localToGlobal(Offset.zero) & box.size).deflate(6),
      onCode: (code) {
        if (!mounted) return;
        setState(() {
          _reads++;
          _firstReadMs ??= _watch.elapsedMilliseconds;
          _last = code;
        });
      },
      onError: (e) {
        if (mounted) setState(() => _status = 'Kamera hatası: ${e.name}');
      },
    );
    if (mounted && _status.startsWith('Kamera açılıyor')) {
      setState(() => _status = 'Kamera açık');
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = TextStyles.code.copyWith(fontSize: 13, color: Palette.paper);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            key: _box,
            decoration: BoxDecoration(
              color: const Color(0xFF0E0D10),
              borderRadius: BorderRadius.circular(Radii.big - 4),
              border: Border.all(color: Palette.paper, width: Stroke.width),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(_status, style: style),
        Text('Okuma: $_reads', style: style),
        Text(
          'İlk okuma: ${_firstReadMs == null ? '-' : '$_firstReadMs ms'}',
          style: style,
        ),
        Text(
          'Son: ${_last ?? '-'}',
          style: style,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
