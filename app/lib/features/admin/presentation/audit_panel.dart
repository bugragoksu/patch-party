import 'package:baglanti_agi/app/theme/tokens.dart';
import 'package:baglanti_agi/features/admin/application/admin_providers.dart';
import 'package:baglanti_agi/features/admin/presentation/admin_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Latest 20 admin actions (`auditLog`), newest first.
class AuditPanel extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(auditLogProvider);
    final entries = async.value;
    return AdminSection(
      title: 'Denetim kaydı',
      child: switch ((entries, async.hasError)) {
        (null, true) => const StatusNote(
          text: 'Denetim kaydı okunamadı.',
          error: true,
        ),
        (null, _) => const Center(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: CircularProgressIndicator(color: Palette.ink),
          ),
        ),
        (final list?, _) when list.isEmpty => Text(
          'Henüz kayıt yok.',
          style: TextStyles.ui.copyWith(color: Palette.inkMuted),
        ),
        (final list?, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final e in list)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 74,
                      child: Text(
                        formatClock(e.at),
                        style: TextStyles.code.copyWith(
                          color: Palette.inkMuted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        actionLabel(e.action),
                        style: TextStyles.ui.copyWith(
                          color: Palette.ink,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      },
    );
  }
}

/// Server action keys (`state:live`, `moderate:rename`, `settings`) in Turkish.
String actionLabel(String action) {
  final parts = action.split(':');
  final value = parts.length > 1 ? parts[1] : '';
  return switch (parts.first) {
    'state' => 'Durum → ${_states[value] ?? value}',
    'moderate' => 'Oyuncu: ${_moderation[value] ?? value}',
    'settings' => 'Ayarlar güncellendi',
    'purge' => 'Veri silindi',
    _ => action,
  };
}

const _states = {
  'draft': 'Taslak',
  'lobby': 'Lobi',
  'live': 'Canlı',
  'ended': 'Bitti',
  'archived': 'Arşiv',
};

const _moderation = {
  'disqualify': 'diskalifiye',
  'restore': 'geri alındı',
  'hideName': 'ad gizlendi',
  'showName': 'ad gösterildi',
  'rename': 'ad değişti',
};
