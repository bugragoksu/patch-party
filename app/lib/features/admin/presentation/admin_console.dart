import 'package:baglanti_agi/app/providers.dart';
import 'package:baglanti_agi/app/theme/tokens.dart';
import 'package:baglanti_agi/core/domain/models.dart';
import 'package:baglanti_agi/core/platform/browser.dart';
import 'package:baglanti_agi/features/admin/application/admin_providers.dart';
import 'package:baglanti_agi/features/admin/presentation/audit_panel.dart';
import 'package:baglanti_agi/features/admin/presentation/danger_panel.dart';
import 'package:baglanti_agi/features/admin/presentation/health_card.dart';
import 'package:baglanti_agi/features/admin/presentation/join_code_card.dart';
import 'package:baglanti_agi/features/admin/presentation/players_panel.dart';
import 'package:baglanti_agi/features/admin/presentation/reveal_panel.dart';
import 'package:baglanti_agi/features/admin/presentation/settings_panel.dart';
import 'package:baglanti_agi/features/admin/presentation/state_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The panel itself, shown only to `admin` claim holders. Two columns on a
/// laptop, one on a phone.
class AdminConsole extends ConsumerWidget {
  const new({super.key});

  static const wideBreakpoint = 980.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventProvider);
    final event = eventAsync.value;
    final eventId = ref.watch(eventIdProvider);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final wide = c.maxWidth >= wideBreakpoint;
            final gutter = wide ? 32.0 : 16.0;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(gutter, 20, gutter, 40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1360),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(event: event, eventId: eventId),
                      const SizedBox(height: 20),
                      if (event == null)
                        _NoEvent(loading: eventAsync.isLoading, id: eventId)
                      else if (wide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  StatePanel(event: event),
                                  RevealPanel(event: event),
                                  JoinCodeCard(event: event),
                                  const HealthCard(),
                                  SettingsPanel(event: event),
                                  DangerPanel(event: event),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            const Expanded(
                              flex: 7,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [PlayersPanel(), AuditPanel()],
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            StatePanel(event: event),
                            RevealPanel(event: event),
                            JoinCodeCard(event: event),
                            const HealthCard(),
                            const PlayersPanel(),
                            SettingsPanel(event: event),
                            const AuditPanel(),
                            DangerPanel(event: event),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const new({required this.event, required this.eventId});

  final EventInfo? event;
  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = ref.watch(staffUserProvider).value?.email;
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Yönetici',
              style: TextStyles.display.copyWith(
                fontSize: 28,
                color: Palette.paper,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              [
                if (event != null && event!.name.isNotEmpty) event!.name,
                eventId,
              ].join(' · '),
              style: TextStyles.ui.copyWith(color: Palette.textMuted),
            ),
          ],
        ),
        const Wrap(
          spacing: 4,
          children: [
            _PageLink(
              label: 'Projeksiyon ekranı',
              icon: Icons.cast,
              route: '/screen',
            ),
            _PageLink(
              label: 'Oyuncu ekranı',
              icon: Icons.smartphone,
              route: '/',
            ),
            _PageLink(
              label: 'Kamera testi',
              icon: Icons.qr_code_scanner,
              route: '/kamera',
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (email != null)
              Flexible(
                child: Text(
                  email,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyles.ui.copyWith(
                    color: Palette.textMuted,
                    fontSize: 13,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () => ref.read(staffAuthProvider).signOut(),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Çıkış'),
              style: TextButton.styleFrom(
                foregroundColor: Palette.paper,
                minimumSize: const Size(44, 44),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NoEvent extends StatelessWidget {
  const new({required this.loading, required this.id});

  final bool loading;
  final String id;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        id.isEmpty
            ? 'APP_EVENT_ID tanımlı değil. Derlemeyi etkinlik kimliğiyle yap.'
            : '"$id" etkinliği bulunamadı. tools/admin/setup-event ile oluştur.',
        style: TextStyles.ui.copyWith(color: Palette.paper, fontSize: 16),
      ),
    );
  }
}

/// Opens another surface of the app in a new tab (FR-30).
class _PageLink extends StatelessWidget {
  const new({required this.label, required this.icon, required this.route});

  final String label;
  final IconData icon;
  final String route;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => Browser.openRoute(route),
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: Palette.yellow,
        minimumSize: const Size(44, 44),
      ),
    );
  }
}
