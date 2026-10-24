import 'package:baglanti_agi/app/providers.dart';
import 'package:baglanti_agi/app/theme/tokens.dart';
import 'package:baglanti_agi/core/domain/failures.dart';
import 'package:baglanti_agi/core/domain/models.dart';
import 'package:baglanti_agi/features/admin/application/admin_providers.dart';
import 'package:baglanti_agi/features/admin/domain/admin_rules.dart';
import 'package:baglanti_agi/features/admin/presentation/admin_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// FR-30: current state, the allowed next states, and an in-page confirm.
class StatePanel extends ConsumerStatefulWidget {
  const new({required this.event, super.key});

  final EventInfo event;

  @override
  ConsumerState<StatePanel> createState() => _StatePanelState();
}

class _StatePanelState extends ConsumerState<StatePanel> {
  EventState? _target;
  final _duration = TextEditingController(text: '$defaultLiveDurationMin');
  bool _busy = false;
  String? _note;
  bool _noteError = false;

  @override
  void didUpdateWidget(StatePanel old) {
    super.didUpdateWidget(old);
    // Someone else changed the state: drop a now-stale confirmation.
    if (old.event.state != widget.event.state && !_busy) _target = null;
  }

  @override
  void dispose() {
    _duration.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final from = widget.event.state;
    final to = _target;
    if (to == null) return;
    int? minutes;
    if (needsDuration(from, to)) {
      minutes = parseLiveDuration(_duration.text);
      if (minutes == null) return;
    }
    setState(() => _busy = true);
    final result = await ref
        .read(adminRepositoryProvider)
        .setEventState(widget.event.id, to, liveDurationMin: minutes);
    if (!mounted) return;
    setState(() {
      _busy = false;
      switch (result) {
        case Ok():
          _target = null;
          _note = 'Durum: ${stateLabel(to)}.';
          _noteError = false;
        case final Err<EventState> err:
          _note = adminFailureMessage(err);
          _noteError = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final from = event.state;
    final now =
        ref.watch(nowProvider).value ?? DateTime.now().millisecondsSinceEpoch;
    final expired = liveExpired(event, now);
    final options = [
      if (canExtend(from)) EventState.live,
      ...allowedTransitions(from),
    ];
    final target = _target;
    return AdminSection(
      title: 'Oyun durumu',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _StateBadge(state: from, expired: expired),
              if (from == EventState.live && event.liveEndAt != null)
                Text(
                  '${expired ? 'Bitti' : 'Bitiş'} '
                  '${formatClock(event.liveEndAt!)}',
                  style: TextStyles.ui.copyWith(
                    color: Palette.inkMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          if (expired)
            const StatusNote(
              text:
                  'Süre doldu: oyuncular okutma yapamıyor. '
                  'Süreyi uzat ya da oyunu bitir.',
              error: true,
            ),
          const SizedBox(height: 14),
          if (options.isEmpty)
            Text(
              from == EventState.archived
                  ? 'Etkinlik arşivlendi. Durum değiştirilemez.'
                  : 'Bu durumdan geçiş yok.',
              style: TextStyles.ui.copyWith(color: Palette.inkMuted),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final to in options)
                  ToolButton(
                    label: transitionLabel(from, to),
                    color: to == EventState.ended
                        ? Palette.red
                        : to == EventState.live
                        ? Palette.green
                        : Palette.yellow,
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            _target = to;
                            _note = null;
                          }),
                  ),
              ],
            ),
          if (target != null) _confirmStrip(from, target),
          if (_note != null) StatusNote(text: _note!, error: _noteError),
        ],
      ),
    );
  }

  Widget _confirmStrip(EventState from, EventState to) {
    final timed = needsDuration(from, to);
    final valid = !timed || parseLiveDuration(_duration.text) != null;
    return ConfirmStrip(
      message: _consequence(from, to),
      confirmLabel: transitionLabel(from, to),
      danger: to == EventState.ended,
      busy: _busy,
      onConfirm: valid ? _confirm : null,
      onCancel: () => setState(() => _target = null),
      child: timed
          ? SizedBox(
              width: 220,
              child: PaperField(
                label: 'Süre (dakika)',
                controller: _duration,
                numeric: true,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                error: valid
                    ? null
                    : '$minLiveDurationMin-$maxLiveDurationMin arası.',
              ),
            )
          : null,
    );
  }

  String _consequence(EventState from, EventState to) => switch ((from, to)) {
    (EventState.draft, EventState.lobby) =>
      'Lobi açılınca oyuncular katılabilir.',
    (EventState.lobby, EventState.live) =>
      'Oyun başlar, bağlantılar puan kazandırır. Süre bitince oyun '
          'kendiliğinden durur.',
    (EventState.lobby, EventState.draft) =>
      'Yeni katılım kapanır. Katılmış oyuncular kalır.',
    (EventState.live, EventState.live) =>
      'Oyun şu andan itibaren girilen süre kadar açık kalır.',
    (EventState.live, EventState.lobby) =>
      'Oyun duraklar; bağlantı kurulamaz, katılım açık kalır.',
    (EventState.live, EventState.ended) =>
      'Oyun biter, sıralama hesaplanır ve kazananlar ekrana gelir.',
    (EventState.ended, EventState.live) =>
      'Bitmiş oyun yeniden açılır. Emin misin?',
    _ => '${stateLabel(to)} durumuna geçilecek.',
  };
}

class _StateBadge extends StatelessWidget {
  const new({required this.state, required this.expired});

  final EventState state;
  final bool expired;

  @override
  Widget build(BuildContext context) {
    final label = expired ? 'Süre doldu' : stateLabel(state);
    final color = expired
        ? Palette.red
        : switch (state) {
            EventState.draft => Palette.textMuted,
            EventState.lobby => Palette.blue,
            EventState.live => Palette.green,
            EventState.ended => Palette.yellow,
            EventState.archived => Palette.textMuted,
          };
    return Semantics(
      label: 'Şu anki durum: $label',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Palette.ink, width: Stroke.width),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state == EventState.live && !expired) ...[
              const Icon(Icons.circle, size: 10, color: Palette.ink),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyles.display.copyWith(
                fontSize: 18,
                color: Palette.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
