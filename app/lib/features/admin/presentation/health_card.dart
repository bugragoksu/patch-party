import 'dart:async';

import 'package:baglanti_agi/app/providers.dart';
import 'package:baglanti_agi/app/theme/tokens.dart';
import 'package:baglanti_agi/features/admin/application/admin_providers.dart';
import 'package:baglanti_agi/features/admin/data/admin_repository.dart';
import 'package:baglanti_agi/features/admin/domain/admin_rules.dart';
import 'package:baglanti_agi/features/admin/presentation/admin_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// NFR-06 health card: aggregate queries every 15 s while the tab is visible.
class HealthCard extends ConsumerStatefulWidget {
  const new({super.key});

  static const interval = Duration(seconds: 15);

  @override
  ConsumerState<HealthCard> createState() => _HealthCardState();
}

class _HealthCardState extends ConsumerState<HealthCard> {
  Timer? _timer;
  late final AppLifecycleListener _lifecycle;
  HealthSample? _sample;
  double? _perMinute;
  bool _loading = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onShow: _start,
      onResume: _start,
      onHide: _stop,
    );
    _start();
  }

  @override
  void dispose() {
    _stop();
    _lifecycle.dispose();
    super.dispose();
  }

  void _start() {
    if (_timer != null) return;
    unawaited(_refresh());
    _timer = Timer.periodic(HealthCard.interval, (_) => unawaited(_refresh()));
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _refresh() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final next = await ref
          .read(adminRepositoryProvider)
          .readHealth(
            ref.read(eventIdProvider),
            nowMs: DateTime.now().millisecondsSinceEpoch,
          );
      if (!mounted) return;
      final prev = _sample;
      setState(() {
        _perMinute = connectionsPerMinute(
          previousCount: prev?.connections,
          previousAtMs: prev?.atMs,
          count: next.connections,
          atMs: next.atMs,
        );
        _sample = next;
        _failed = false;
      });
    } on Object catch (e, st) {
      unawaited(
        ref.read(errorReporterProvider).report(e, st, surface: 'admin'),
      );
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _sample;
    String n(int? v) => v == null ? '–' : '$v';
    return AdminSection(
      title: 'Sağlık',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (s != null)
            Text(
              formatClock(s.atMs),
              style: TextStyles.ui.copyWith(
                color: Palette.inkMuted,
                fontSize: 12,
              ),
            ),
          IconButton(
            tooltip: 'Şimdi yenile',
            onPressed: _loading ? null : () => unawaited(_refresh()),
            icon: _loading
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Palette.ink,
                    ),
                  )
                : const Icon(Icons.refresh, color: Palette.ink),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Metric(label: 'Katılan', value: n(s?.players)),
              _Metric(label: 'Aktif (son 5 dk)', value: n(s?.activePlayers)),
              _Metric(label: 'Bağlantı', value: n(s?.connections)),
              _Metric(
                label: 'Bağlantı / dk',
                value: _perMinute == null
                    ? '–'
                    : _perMinute!.toStringAsFixed(1),
              ),
              _Metric(
                label: 'Hatalı deneme',
                value: n(s?.totalFailures),
                alert: (s?.totalFailures ?? 0) > 0,
              ),
              _Metric(
                label: 'Engelli oyuncu',
                value: n(s?.blockedPlayers),
                alert: (s?.blockedPlayers ?? 0) > 0,
              ),
            ],
          ),
          if (_failed)
            const StatusNote(
              text: 'Sağlık verisi okunamadı. 15 sn sonra yeniden denenecek.',
              error: true,
            ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const new({required this.label, required this.value, this.alert = false});

  final String label;
  final String value;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Container(
        width: 132,
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        decoration: BoxDecoration(
          color: alert ? Palette.yellow : Palette.paper,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Palette.ink, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyles.ui.copyWith(
                color: Palette.inkMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyles.code.copyWith(color: Palette.ink, fontSize: 24),
            ),
          ],
        ),
      ),
    );
  }
}
