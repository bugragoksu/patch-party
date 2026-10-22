import 'package:baglanti_agi/app/theme/tokens.dart';
import 'package:baglanti_agi/core/domain/failures.dart';
import 'package:baglanti_agi/core/domain/models.dart';
import 'package:baglanti_agi/features/admin/application/admin_providers.dart';
import 'package:baglanti_agi/features/admin/domain/admin_rules.dart';
import 'package:baglanti_agi/features/admin/presentation/admin_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Runtime settings (architecture §11): validated like the server schema,
/// saved as a partial patch via `updateEventConfig`.
class SettingsPanel extends ConsumerStatefulWidget {
  const new({required this.event, super.key});

  final EventInfo event;

  @override
  ConsumerState<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends ConsumerState<SettingsPanel> {
  final _name = TextEditingController();
  final _subtitle = TextEditingController();
  final List<TextEditingController> _prizes = List.generate(
    maxPrizeLines,
    (_) => TextEditingController(),
  );
  final _cooldown = TextEditingController();
  final _ttl = TextEditingController();
  final _maxConn = TextEditingController();
  final _maxPlayers = TextEditingController();
  bool _appCheck = false;
  bool _badges = true;
  bool _playerRank = true;

  Map<SettingsField, String> _errors = const {};
  bool _dirty = false;
  bool _confirming = false;
  bool _busy = false;
  String? _note;
  bool _noteError = false;

  @override
  void initState() {
    super.initState();
    _load(widget.event.settings);
  }

  @override
  void didUpdateWidget(SettingsPanel old) {
    super.didUpdateWidget(old);
    // Follow server changes unless the admin is mid-edit.
    if (!identical(old.event.settings, widget.event.settings) &&
        !_dirty &&
        !_busy) {
      _load(widget.event.settings);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _subtitle,
      ..._prizes,
      _cooldown,
      _ttl,
      _maxConn,
      _maxPlayers,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _load(EventSettings s) {
    final d = SettingsDraft.fromSettings(s);
    _name.text = d.displayName;
    _subtitle.text = d.subtitle;
    for (var i = 0; i < maxPrizeLines; i++) {
      _prizes[i].text = d.prizes[i];
    }
    _cooldown.text = d.cooldownSec;
    _ttl.text = d.requestTtlSec;
    _maxConn.text = d.maxConnPerPlayer;
    _maxPlayers.text = d.maxPlayers;
    _appCheck = d.appCheckEnforce;
    _badges = d.badges;
    _playerRank = d.playerRank;
    _errors = const {};
    _dirty = false;
    _confirming = false;
  }

  SettingsDraft get _draft => SettingsDraft(
    displayName: _name.text,
    subtitle: _subtitle.text,
    prizes: [for (final p in _prizes) p.text],
    cooldownSec: _cooldown.text,
    requestTtlSec: _ttl.text,
    maxConnPerPlayer: _maxConn.text,
    maxPlayers: _maxPlayers.text,
    appCheckEnforce: _appCheck,
    badges: _badges,
    playerRank: _playerRank,
  );

  void _changed() => setState(() {
    _dirty = true;
    _confirming = false;
    _note = null;
    if (_errors.isNotEmpty) _errors = _draft.validate();
  });

  void _review() {
    final errors = _draft.validate();
    setState(() {
      _errors = errors;
      if (errors.isNotEmpty) {
        _note = 'Kırmızı alanları düzelt.';
        _noteError = true;
        return;
      }
      if (_draft.patchAgainst(widget.event.settings).isEmpty) {
        _note = 'Değişiklik yok.';
        _noteError = false;
        _dirty = false;
        return;
      }
      _confirming = true;
      _note = null;
    });
  }

  Future<void> _save() async {
    final patch = _draft.patchAgainst(widget.event.settings);
    setState(() => _busy = true);
    final result = await ref
        .read(adminRepositoryProvider)
        .updateEventConfig(widget.event.id, patch);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _confirming = false;
      switch (result) {
        case Ok():
          _dirty = false;
          _note = 'Ayarlar kaydedildi.';
          _noteError = false;
        case final Err<void> err:
          _note = adminFailureMessage(err);
          _noteError = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final changes = _confirming
        ? _draft.patchAgainst(widget.event.settings).keys.join(', ')
        : '';
    return AdminSection(
      title: 'Ayarlar',
      trailing: _dirty
          ? TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() {
                      _load(widget.event.settings);
                      _note = null;
                    }),
              style: TextButton.styleFrom(foregroundColor: Palette.ink),
              child: const Text('Değişiklikleri at'),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PaperField(
            label: 'Görünen ad',
            controller: _name,
            error: _errors[SettingsField.displayName],
            onChanged: (_) => _changed(),
          ),
          const SizedBox(height: 12),
          PaperField(
            label: 'Alt başlık',
            controller: _subtitle,
            error: _errors[SettingsField.subtitle],
            onChanged: (_) => _changed(),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < maxPrizeLines; i++) ...[
            PaperField(
              label: 'Ödül ${i + 1}',
              controller: _prizes[i],
              hint: i == 0 ? 'ör. 1. Kulaklık' : null,
              error: i == maxPrizeLines - 1
                  ? _errors[SettingsField.prizes]
                  : null,
              onChanged: (_) => _changed(),
            ),
            const SizedBox(height: 12),
          ],
          LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth >= 420 ? (c.maxWidth - 12) / 2 : c.maxWidth;
              Widget num(
                String label,
                TextEditingController ctl,
                SettingsField f,
              ) => SizedBox(
                width: w,
                child: PaperField(
                  label: label,
                  controller: ctl,
                  numeric: true,
                  error: _errors[f],
                  onChanged: (_) => _changed(),
                ),
              );
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  num('Bekleme (sn)', _cooldown, SettingsField.cooldownSec),
                  num('İstek süresi (sn)', _ttl, SettingsField.requestTtlSec),
                  num(
                    'Oyuncu başı bağlantı tavanı',
                    _maxConn,
                    SettingsField.maxConnPerPlayer,
                  ),
                  num('En fazla oyuncu', _maxPlayers, SettingsField.maxPlayers),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          _Toggle(
            label: 'App Check zorunlu',
            value: _appCheck,
            onChanged: (v) {
              _appCheck = v;
              _changed();
            },
          ),
          _Toggle(
            label: 'Rozetler',
            value: _badges,
            onChanged: (v) {
              _badges = v;
              _changed();
            },
          ),
          _Toggle(
            label: 'Oyuncuya kendi sırasını göster',
            value: _playerRank,
            onChanged: (v) {
              _playerRank = v;
              _changed();
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ToolButton(
              label: 'Kaydet',
              onPressed: _dirty && !_busy && !_confirming ? _review : null,
            ),
          ),
          if (_confirming)
            ConfirmStrip(
              message:
                  'Değişen alanlar: $changes. Ayarlar oyunculara hemen '
                  'uygulanır.',
              confirmLabel: 'Kaydet',
              busy: _busy,
              onConfirm: _save,
              onCancel: () => setState(() => _confirming = false),
            ),
          if (_note != null) StatusNote(text: _note!, error: _noteError),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const new({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      value: value,
      onChanged: onChanged,
      activeThumbColor: Palette.ink,
      activeTrackColor: Palette.green,
      inactiveThumbColor: Palette.ink,
      inactiveTrackColor: Palette.paper,
      trackOutlineColor: const WidgetStatePropertyAll(Palette.ink),
      title: Text(
        label,
        style: TextStyles.ui.copyWith(
          color: Palette.ink,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
