import 'package:baglanti_agi/app/theme/tokens.dart';
import 'package:baglanti_agi/core/domain/models.dart';
import 'package:baglanti_agi/core/ui/feedback.dart';
import 'package:baglanti_agi/features/projector/presentation/projector_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Design size of the projector stage (04-design.md §5).
const stageSize = Size(1920, 1080);

/// Lays a scene out on a fixed 1920×1080 stage and scales it to the screen,
/// so a 1280×720 projector shows the same composition, just smaller.
class ProjectorCanvas extends StatelessWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Palette.asphalt,
      child: SizedBox.expand(
        child: FittedBox(
          child: SizedBox.fromSize(
            size: stageSize,
            child: MediaQuery.withNoTextScaling(child: child),
          ),
        ),
      ),
    );
  }
}

/// Stage padding plus the "stream lost, showing last data" banner.
class SceneFrame extends StatelessWidget {
  const new({required this.child, super.key, this.error = false, this.onRetry});

  final Widget child;
  final bool error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(48, 40, 48, 44),
            child: child,
          ),
        ),
        if (error && onRetry != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: Center(child: StreamErrorBanner(onRetry: onRetry!)),
          ),
      ],
    );
  }
}

/// Spinner while a stream has no data yet, ErrorCard if it failed first.
class AsyncBlocker extends StatelessWidget {
  const new({required this.value, required this.onRetry, super.key});

  final AsyncValue<Object?> value;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (value.hasError) {
      return ErrorCard(
        message: 'Oyun verisi okunamadı. Bağlantıyı kontrol edip tekrar dene.',
        actionLabel: 'Tekrar dene',
        onAction: onRetry,
      );
    }
    return const Center(
      child: SizedBox.square(
        dimension: 64,
        child: CircularProgressIndicator(color: Palette.yellow, strokeWidth: 6),
      ),
    );
  }
}

/// Event name and subtitle from settings.
class EventTitle extends StatelessWidget {
  const new({required this.event, super.key, this.size = 48});

  final EventInfo event;
  final double size;

  @override
  Widget build(BuildContext context) {
    final subtitle = event.settings.subtitle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          event.settings.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyles.display.copyWith(
            fontSize: size,
            color: Palette.paper,
          ),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyles.ui.copyWith(
              fontSize: size * 0.42 < 22 ? 22 : size * 0.42,
              color: Palette.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}
