import 'package:baglanti_agi/app/providers.dart';
import 'package:baglanti_agi/app/theme/tokens.dart';
import 'package:baglanti_agi/core/domain/models.dart';
import 'package:baglanti_agi/core/domain/token.dart';
import 'package:baglanti_agi/features/admin/application/admin_providers.dart';
import 'package:baglanti_agi/features/admin/presentation/admin_widgets.dart';
import 'package:baglanti_agi/features/projector/presentation/format.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The join code the projector shows, for reading out or sharing the link
/// while the lobby or the game is open.
class JoinCodeCard extends ConsumerWidget {
  const new({required this.event, super.key});

  final EventInfo event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (event.state != EventState.lobby && event.state != EventState.live) {
      return const SizedBox.shrink();
    }
    final seed = ref.watch(adminJoinSeedProvider);
    final now =
        ref.watch(nowProvider).value ?? DateTime.now().millisecondsSinceEpoch;
    final windowSec = event.settings.joinWindowSec;
    final seedValue = seed.value;
    final code = seedValue == null || seedValue.isEmpty
        ? null
        : joinCodeFor(seedValue, event.id, windowOf(now, windowSec));
    final secondsLeft = windowSec - (now ~/ 1000) % windowSec;
    final link = code == null ? null : joinLink(webOrigin(), code);
    final muted = TextStyles.ui.copyWith(color: Palette.inkMuted);

    return AdminSection(
      title: 'Katılım kodu',
      child: code == null
          ? Text(
              seed.hasError || seed.hasValue
                  ? 'Katılım kodu okunamadı.'
                  : 'Yükleniyor…',
              style: muted,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    SelectableText(
                      formatJoinCode(code),
                      style: TextStyles.code.copyWith(
                        fontSize: 40,
                        color: Palette.ink,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      '${formatRemaining(now + secondsLeft * 1000, now)} '
                      'sonra değişir',
                      style: muted,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        link!,
                        maxLines: 1,
                        style: muted.copyWith(fontSize: 13),
                      ),
                    ),
                    InkOutlineButton(
                      label: 'Linki kopyala',
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: link));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Link kopyalandı.')),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Kod değiştikten sonra eski kod birkaç dakika daha geçerli.',
                  style: muted.copyWith(fontSize: 13),
                ),
              ],
            ),
    );
  }
}
