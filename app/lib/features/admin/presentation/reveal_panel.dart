import 'package:baglanti_agi/app/theme/tokens.dart';
import 'package:baglanti_agi/core/domain/failures.dart';
import 'package:baglanti_agi/core/domain/models.dart';
import 'package:baglanti_agi/features/admin/application/admin_providers.dart';
import 'package:baglanti_agi/features/admin/presentation/admin_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// After the game ends the host announces the results one place at a time;
/// the projector and the phones follow event.reveal.
class RevealPanel extends ConsumerStatefulWidget {
  const new({required this.event, super.key});

  final EventInfo event;

  @override
  ConsumerState<RevealPanel> createState() => _RevealPanelState();
}

class _RevealPanelState extends ConsumerState<RevealPanel> {
  bool _busy = false;
  String? _error;

  Future<void> _go(int step) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref
        .read(adminRepositoryProvider)
        .revealResults(widget.event.id, step);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (result case final Err<int> err) _error = adminFailureMessage(err);
    });
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    if (event.state != EventState.ended) return const SizedBox.shrink();
    final reveal = event.reveal;
    final next = switch (reveal) {
      0 => '3.’yü açıkla',
      1 => '2.’yi açıkla',
      2 => '1.’yi açıkla',
      _ => null,
    };
    final status = switch (reveal) {
      0 => 'Perdede "Oyun bitti" görünüyor. Kazananlar henüz gizli.',
      1 => 'Üçüncü açıklandı.',
      2 => 'İkinci açıklandı.',
      _ => 'Bütün kazananlar açıklandı. Telefonlarda sıralama göründü.',
    };
    return AdminSection(
      title: 'Sonuçları açıkla',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(status, style: TextStyles.ui.copyWith(color: Palette.inkMuted)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (next != null)
                ToolButton(
                  label: next,
                  color: reveal == 2 ? Palette.yellow : Palette.green,
                  busy: _busy,
                  onPressed: _busy ? null : () => _go(reveal + 1),
                ),
              if (reveal > 0)
                InkOutlineButton(
                  label: 'Baştan al',
                  onPressed: _busy ? null : () => _go(0),
                ),
            ],
          ),
          if (_error != null) StatusNote(text: _error!, error: true),
        ],
      ),
    );
  }
}
