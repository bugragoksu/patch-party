import 'dart:async';

import 'package:baglanti_agi/app/providers.dart';
import 'package:baglanti_agi/app/theme/tokens.dart';
import 'package:baglanti_agi/core/observability/error_reporter.dart';
import 'package:baglanti_agi/core/platform/camera_scanner.dart';
import 'package:baglanti_agi/core/ui/buttons.dart';
import 'package:baglanti_agi/core/ui/chips.dart';
import 'package:baglanti_agi/features/play/application/play_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Viewfinder (FR-04). Flutter reserves the rectangle; web/scanner.js puts
/// the camera there. Manual entry (FR-05) is always one tap away.
class ScanView extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<ScanView> createState() => _ScanViewState();
}

class _ScanViewState extends ConsumerState<ScanView>
    with WidgetsBindingObserver {
  final GlobalKey<State<StatefulWidget>> _viewfinder = GlobalKey();
  late final CameraScanner _scanner = ref.read(cameraScannerProvider);
  CameraError? _error;
  bool _slow = false;
  Timer? _slowTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
      ..addObserver(this)
      ..addPostFrameCallback((_) => _start());
    _slowTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) setState(() => _slow = true);
    });
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _scanner.stop();
    super.dispose();
  }

  @override
  void didChangeMetrics() => WidgetsBinding.instance.addPostFrameCallback((_) {
    final rect = _rect();
    if (rect != null) _scanner.place(rect);
  });

  Rect? _rect() {
    final box = _viewfinder.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Future<void> _start() async {
    final rect = _rect();
    if (rect == null || !mounted) return;
    setState(() => _error = null);
    await _scanner.start(
      rect.deflate(6),
      onCode: (code) =>
          unawaited(ref.read(playControllerProvider.notifier).submitCode(code)),
      onError: (error) {
        if (!mounted) return;
        ref
            .read(errorReporterProvider)
            .breadcrumb(AppEvent.cameraDenied, detail: error.name);
        setState(() => _error = error);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(playControllerProvider.select((s) => s.busy));
    final controller = ref.read(playControllerProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            key: _viewfinder,
            decoration: BoxDecoration(
              color: const Color(0xFF0E0D10),
              borderRadius: BorderRadius.circular(Radii.big - 4),
              border: Border.all(color: Palette.paper, width: Stroke.width),
            ),
            child: _error == null
                ? _Brackets(busy: busy)
                : _CameraProblem(error: _error!, onRetry: _start),
          ),
        ),
        const SizedBox(height: 14),
        if (_slow && _error == null) ...[
          NoticeBox(
            child: Text(
              'Okunmuyor mu? Ekran parlaklığını artırmasını iste '
              'ya da kodu elle gir.',
              style: TextStyles.ui.copyWith(fontSize: 13),
            ),
          ),
          const SizedBox(height: 12),
        ],
        GhostButton(
          label: 'Kamera yok mu? Kodu elle gir',
          onPressed: controller.showManual,
        ),
      ],
    );
  }
}

class _Brackets extends StatelessWidget {
  const new({required this.busy});

  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (final a in const [
          Alignment.topLeft,
          Alignment.topRight,
          Alignment.bottomLeft,
          Alignment.bottomRight,
        ])
          Align(
            alignment: a,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: CustomPaint(
                size: const Size.square(36),
                painter: _Corner(a),
              ),
            ),
          ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 22),
            child: Text(
              busy ? 'Gönderiliyor…' : "QR'ı çerçeveye al",
              style: TextStyles.ui.copyWith(
                fontSize: 13,
                color: const Color(0xFFD8D3C8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Corner extends CustomPainter {
  new(this.alignment);
  final Alignment alignment;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Palette.yellow
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final x = alignment.x < 0 ? 0.0 : size.width;
    final y = alignment.y < 0 ? 0.0 : size.height;
    final dx = alignment.x < 0 ? size.width : -size.width;
    final dy = alignment.y < 0 ? size.height : -size.height;
    canvas
      ..drawLine(Offset(x, y), Offset(x + dx, y), p)
      ..drawLine(Offset(x, y), Offset(x, y + dy), p);
  }

  @override
  bool shouldRepaint(_Corner old) => old.alignment != alignment;
}

class _CameraProblem extends StatelessWidget {
  const new({required this.error, required this.onRetry});

  final CameraError error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final text = switch (error) {
      CameraError.denied =>
        'Kamera izni verilmedi. Tarayıcı ayarlarından izin verebilir '
            'ya da kodu elle girebilirsin.',
      CameraError.noCamera =>
        'Bu cihazda kamera bulunamadı. Kodu elle girebilirsin.',
      CameraError.failed =>
        'Kamera açılamadı. Tekrar dene ya da kodu elle gir.',
    };
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyles.ui.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 16),
          LinkButton(label: 'Tekrar dene', onPressed: onRetry),
        ],
      ),
    );
  }
}
