import 'package:baglanti_agi/app/providers.dart';
import 'package:baglanti_agi/app/theme/tokens.dart';
import 'package:baglanti_agi/core/domain/failures.dart';
import 'package:baglanti_agi/core/domain/models.dart';
import 'package:baglanti_agi/core/domain/names.dart';
import 'package:baglanti_agi/features/admin/application/admin_providers.dart';
import 'package:baglanti_agi/features/admin/data/admin_repository.dart';
import 'package:baglanti_agi/features/admin/domain/admin_rules.dart';
import 'package:baglanti_agi/features/admin/presentation/admin_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _Row {
  const new({
    required this.player,
    required this.failures,
    required this.reasons,
  });

  final Player player;
  final int failures;
  final List<SuspicionReason> reasons;

  bool get suspicious => reasons.isNotEmpty;
}

/// FR-31 / FR-32: searchable players with suspicion flags and moderation.
class PlayersPanel extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<PlayersPanel> createState() => _PlayersPanelState();
}

class _PlayersPanelState extends ConsumerState<PlayersPanel> {
  final _search = TextEditingController();
  final _rename = TextEditingController();
  bool _onlySuspicious = false;
  String? _openUid;
  ModerationAction? _pending;
  bool _busy = false;
  String? _note;
  bool _noteError = false;

  @override
  void dispose() {
    _search.dispose();
    _rename.dispose();
    super.dispose();
  }

  /// Every player with failures and suspicion reasons, suspicious first.
  List<_Row> _allRows(ReviewData data) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return [
      for (final p in data.players)
        _Row(
          player: p,
          failures: data.rateLimits[p.uid]?.totalFailures ?? 0,
          reasons: suspicionReasons(
            connectionCount: p.connectionCount,
            failures: data.rateLimits[p.uid]?.totalFailures ?? 0,
            joinedAtMs: p.joinedAt,
            nowMs: now,
          ),
        ),
    ]..sort((a, b) {
      if (a.suspicious != b.suspicious) return a.suspicious ? -1 : 1;
      return b.player.score.compareTo(a.player.score);
    });
  }

  List<_Row> _visible(List<_Row> all) {
    final q = normalizeName(_search.text);
    return [
      for (final r in all)
        if ((!_onlySuspicious || r.suspicious) &&
            (q.isEmpty || normalizeName(r.player.displayName).contains(q)))
          r,
    ];
  }

  void _toggle(String uid) => setState(() {
    _openUid = _openUid == uid ? null : uid;
    _pending = null;
    _note = null;
  });

  void _ask(ModerationAction action, Player p) => setState(() {
    _pending = action;
    _note = null;
    if (action == ModerationAction.rename) _rename.text = p.displayName;
  });

  Future<void> _run(Player p, ModerationAction action) async {
    String? name;
    if (action == ModerationAction.rename) {
      name = cleanDisplayName(_rename.text);
      if (!isValidDisplayName(name)) return;
    }
    setState(() => _busy = true);
    final result = await ref
        .read(adminRepositoryProvider)
        .moderatePlayer(
          ref.read(eventIdProvider),
          p.uid,
          action,
          displayName: name,
        );
    if (!mounted) return;
    setState(() {
      _busy = false;
      switch (result) {
        case Ok():
          _pending = null;
          _note = '${p.displayName}: ${_doneLabel(action)}';
          _noteError = false;
        case final Err<void> err:
          _note = adminFailureMessage(err);
          _noteError = true;
      }
    });
    if (result is Ok) ref.invalidate(reviewDataProvider);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(reviewDataProvider);
    final data = async.value;
    final all = data == null ? const <_Row>[] : _allRows(data);
    final rows = _visible(all);
    final suspiciousCount = all.where((r) => r.suspicious).length;
    return AdminSection(
      title: 'Oyuncular ve inceleme',
      trailing: IconButton(
        tooltip: 'Listeyi yenile',
        onPressed: async.isLoading
            ? null
            : () => ref.invalidate(reviewDataProvider),
        icon: async.isLoading
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Palette.ink,
                ),
              )
            : const Icon(Icons.refresh, color: Palette.ink),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PaperField(
            label: 'Ada göre ara',
            controller: _search,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Checkbox(
                value: _onlySuspicious,
                onChanged: (v) => setState(() => _onlySuspicious = v ?? false),
                activeColor: Palette.ink,
                checkColor: Palette.yellow,
                side: const BorderSide(color: Palette.ink, width: 2),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      setState(() => _onlySuspicious = !_onlySuspicious),
                  child: Text(
                    'Yalnızca şüpheliler ($suspiciousCount)',
                    style: TextStyles.ui.copyWith(
                      color: Palette.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (data != null)
                Text(
                  '${rows.length} / ${data.players.length}',
                  style: TextStyles.ui.copyWith(
                    color: Palette.inkMuted,
                    fontSize: 13,
                  ),
                ),
            ],
          ),
          Text(
            'Şüpheli: en az 5 hatalı deneme ya da katıldığından beri '
            "30 sn'de birden hızlı bağlantı.",
            style: TextStyles.ui.copyWith(
              color: Palette.inkMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          if (async.hasError && data == null)
            const StatusNote(
              text: 'Oyuncu listesi okunamadı. Yenilemeyi dene.',
              error: true,
            )
          else if (data == null)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(color: Palette.ink),
              ),
            )
          else if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                data.players.isEmpty ? 'Henüz oyuncu yok.' : 'Eşleşme yok.',
                style: TextStyles.ui.copyWith(color: Palette.inkMuted),
              ),
            )
          else
            for (final r in rows) _rowView(r),
        ],
      ),
    );
  }

  Widget _rowView(_Row r) {
    final p = r.player;
    final open = _openUid == p.uid;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: r.suspicious
            ? Color.alphaBlend(
                Palette.yellow.withValues(alpha: 0.22),
                Palette.paper,
              )
            : Palette.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Palette.ink, width: open ? Stroke.width : 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _toggle(p.uid),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 160),
                      child: Text(
                        p.displayName,
                        style: TextStyles.ui.copyWith(
                          color: Palette.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          decoration: p.disqualified
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                    _stat('puan', p.score),
                    _stat('bağlantı', p.connectionCount),
                    _stat('hata', r.failures),
                    if (p.disqualified)
                      const Tag(label: 'diskalifiye', color: Palette.red),
                    if (p.nameHidden)
                      const Tag(label: 'ad gizli', color: Palette.textMuted),
                    for (final reason in r.reasons)
                      Tag(label: 'şüpheli: ${suspicionLabel(reason)}'),
                  ],
                ),
              ),
            ),
            if (open) _actions(p),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, int value) => Text.rich(
    TextSpan(
      children: [
        TextSpan(
          text: '$value ',
          style: TextStyles.code.copyWith(color: Palette.ink, fontSize: 15),
        ),
        TextSpan(
          text: label,
          style: TextStyles.ui.copyWith(color: Palette.inkMuted, fontSize: 13),
        ),
      ],
    ),
  );

  Widget _actions(Player p) {
    final pending = _pending;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(color: Palette.ink, thickness: 1),
          Text(
            [
              'Kod ${p.playerCode}',
              if (p.joinedAt > 0) 'katılım ${formatClock(p.joinedAt)}',
              if (p.lastConnectionAt != null)
                'son bağlantı ${formatClock(p.lastConnectionAt!)}',
            ].join(' · '),
            style: TextStyles.ui.copyWith(
              color: Palette.inkMuted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (p.disqualified)
                ToolButton(
                  label: 'Geri al',
                  color: Palette.green,
                  onPressed: _busy
                      ? null
                      : () => _ask(ModerationAction.restore, p),
                )
              else
                ToolButton(
                  label: 'Diskalifiye et',
                  color: Palette.red,
                  onPressed: _busy
                      ? null
                      : () => _ask(ModerationAction.disqualify, p),
                ),
              if (p.nameHidden)
                InkOutlineButton(
                  label: 'Adı göster',
                  onPressed: _busy
                      ? null
                      : () => _ask(ModerationAction.showName, p),
                )
              else
                InkOutlineButton(
                  label: 'Adı gizle',
                  onPressed: _busy
                      ? null
                      : () => _ask(ModerationAction.hideName, p),
                ),
              InkOutlineButton(
                label: 'Adı değiştir',
                onPressed: _busy
                    ? null
                    : () => _ask(ModerationAction.rename, p),
              ),
            ],
          ),
          if (pending != null) _confirm(p, pending),
          if (_note != null) StatusNote(text: _note!, error: _noteError),
        ],
      ),
    );
  }

  Widget _confirm(Player p, ModerationAction action) {
    final rename = action == ModerationAction.rename;
    final nameOk = !rename || isValidDisplayName(_rename.text);
    return ConfirmStrip(
      message: _question(action, p.displayName),
      confirmLabel: _confirmLabel(action),
      danger:
          action == ModerationAction.disqualify ||
          action == ModerationAction.hideName,
      busy: _busy,
      onConfirm: nameOk ? () => _run(p, action) : null,
      onCancel: () => setState(() => _pending = null),
      child: rename
          ? PaperField(
              label: 'Yeni ad',
              controller: _rename,
              autofocus: true,
              maxLength: 64,
              onChanged: (_) => setState(() {}),
              error: nameOk
                  ? null
                  : '$nameMinLength-$nameMaxLength harf, rakam, boşluk ya da '
                        ". ' - kullan.",
            )
          : null,
    );
  }

  String _question(ModerationAction a, String name) => switch (a) {
    ModerationAction.disqualify =>
      '$name diskalifiye edilsin mi? Sıralamada görünmez, bağlantı kuramaz.',
    ModerationAction.restore => '$name geri alınsın mı? Oyuna geri döner.',
    ModerationAction.hideName =>
      '$name adı ekranda gizlensin mi? Projeksiyonda "Oyuncu" görünür.',
    ModerationAction.showName => '$name adı yeniden gösterilsin mi?',
    ModerationAction.rename => '$name için yeni ad:',
  };

  String _confirmLabel(ModerationAction a) => switch (a) {
    ModerationAction.disqualify => 'Diskalifiye et',
    ModerationAction.restore => 'Geri al',
    ModerationAction.hideName => 'Gizle',
    ModerationAction.showName => 'Göster',
    ModerationAction.rename => 'Adı kaydet',
  };

  String _doneLabel(ModerationAction a) => switch (a) {
    ModerationAction.disqualify => 'diskalifiye edildi.',
    ModerationAction.restore => 'geri alındı.',
    ModerationAction.hideName => 'adı gizlendi.',
    ModerationAction.showName => 'adı gösteriliyor.',
    ModerationAction.rename => 'adı değiştirildi.',
  };
}
