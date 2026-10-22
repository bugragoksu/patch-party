import 'package:baglanti_agi/app/theme/tokens.dart';
import 'package:baglanti_agi/core/domain/failures.dart';
import 'package:baglanti_agi/core/domain/models.dart';
import 'package:baglanti_agi/features/admin/application/admin_providers.dart';
import 'package:baglanti_agi/features/admin/presentation/admin_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// FR-33: irreversible purge. Only offered once the event has ended, and only
/// after the admin types the event id.
class DangerPanel extends ConsumerStatefulWidget {
  const new({required this.event, super.key});

  final EventInfo event;

  @override
  ConsumerState<DangerPanel> createState() => _DangerPanelState();
}

class _DangerPanelState extends ConsumerState<DangerPanel> {
  final _confirm = TextEditingController();
  bool _open = false;
  bool _busy = false;
  String? _note;
  bool _noteError = false;

  @override
  void dispose() {
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _purge() async {
    setState(() => _busy = true);
    final result = await ref
        .read(adminRepositoryProvider)
        .purgeEvent(widget.event.id, _confirm.text.trim());
    if (!mounted) return;
    setState(() {
      _busy = false;
      switch (result) {
        case Ok(:final value):
          _open = false;
          _confirm.clear();
          _note = 'Veri silindi. $value hesap kaldırıldı.';
          _noteError = false;
        case final Err<int> err:
          _note = adminFailureMessage(err);
          _noteError = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final ended = event.state == EventState.ended;
    final matches = _confirm.text.trim() == event.id;
    final muted = TextStyles.ui.copyWith(color: Palette.inkMuted);
    return AdminSection(
      title: 'Tehlikeli bölge',
      outline: Palette.red,
      shadow: Palette.red,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Etkinlik verisini sil (arşivle)',
            style: TextStyles.title.copyWith(color: Palette.ink, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            'Tüm oyuncular, bağlantılar ve hesaplar geri dönüşsüz silinir. '
            'Yalnızca toplam sayılar kalır.',
            style: muted,
          ),
          const SizedBox(height: 12),
          if (event.state == EventState.archived)
            Text('Etkinlik zaten arşivlendi.', style: muted)
          else if (!ended)
            Text(
              'Silme yalnızca oyun "Bitti" durumundayken açılır.',
              style: muted,
            )
          else if (!_open)
            Align(
              alignment: Alignment.centerLeft,
              child: ToolButton(
                label: 'Veriyi silmeye başla',
                color: Palette.red,
                onPressed: () => setState(() {
                  _open = true;
                  _note = null;
                }),
              ),
            )
          else
            ConfirmStrip(
              danger: true,
              message:
                  'Onaylamak için etkinlik kimliğini yaz: ${event.id}. '
                  'Bu işlem geri alınamaz.',
              confirmLabel: 'Kalıcı olarak sil',
              busy: _busy,
              onConfirm: matches ? _purge : null,
              onCancel: () => setState(() {
                _open = false;
                _confirm.clear();
              }),
              child: PaperField(
                label: 'Etkinlik kimliği',
                controller: _confirm,
                autofocus: true,
                onChanged: (_) => setState(() {}),
              ),
            ),
          if (_note != null) StatusNote(text: _note!, error: _noteError),
        ],
      ),
    );
  }
}
