import 'package:baglanti_agi/app/theme/tokens.dart';
import 'package:baglanti_agi/core/domain/models.dart';
import 'package:baglanti_agi/core/ui/sticker.dart';
import 'package:baglanti_agi/features/play/application/questions.dart';
import 'package:baglanti_agi/features/play/application/session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// FR-09: everyone I connected with, newest first, with our question.
class ConnectionsList extends ConsumerWidget {
  const new({required this.me, super.key});

  final Player me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connections = ref.watch(myConnectionsProvider).value ?? const [];
    final pool = ref.watch(questionPoolProvider).value;
    if (connections.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(28),
        child: Text(
          'Henüz bağlantın yok. İlk bağlantını kur!',
          textAlign: TextAlign.center,
          style: TextStyles.ui.copyWith(fontSize: 15, color: Palette.textMuted),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      itemCount: connections.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final c = connections[i];
        final other = c.names[c.otherThan(me.uid)] ?? '';
        final question = pool?.questionFor(c.questionKey, c.questionSeed);
        return Sticker(
          radius: 18,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      other,
                      style: TextStyles.title.copyWith(
                        fontSize: 17,
                        color: Palette.ink,
                      ),
                    ),
                  ),
                  Text(
                    '+${c.points}',
                    style: TextStyles.code.copyWith(
                      fontSize: 15,
                      color: Palette.ink,
                    ),
                  ),
                ],
              ),
              if (question != null) ...[
                const SizedBox(height: 6),
                Text(
                  question,
                  style: TextStyles.ui.copyWith(
                    fontSize: 13,
                    color: Palette.inkMuted,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

Future<void> showConnectionsSheet(BuildContext context, Player me) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Palette.asphalt,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.big)),
      side: BorderSide(color: Palette.line, width: 2),
    ),
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.85,
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            'Bağlantılarım',
            style: TextStyles.display.copyWith(
              fontSize: 22,
              color: Palette.paper,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: ConnectionsList(me: me)),
        ],
      ),
    ),
  );
}
