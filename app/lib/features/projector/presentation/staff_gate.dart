import 'package:baglanti_agi/app/providers.dart';
import 'package:baglanti_agi/app/theme/tokens.dart';
import 'package:baglanti_agi/core/ui/buttons.dart';
import 'package:baglanti_agi/core/ui/feedback.dart';
import 'package:baglanti_agi/core/ui/sticker.dart';
import 'package:baglanti_agi/features/projector/application/projector_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shows [child] only to a Google-signed-in account with the `projector` or
/// `admin` claim (SEC-40). The projector laptop signs in once.
class StaffGate extends ConsumerWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(staffUserProvider);
    if (!auth.hasValue) {
      if (auth.hasError) {
        return ErrorCard(
          message: 'Oturum bilgisi okunamadı. Sayfayı yenileyip tekrar dene.',
          actionLabel: 'Tekrar dene',
          onAction: () => ref.invalidate(staffUserProvider),
        );
      }
      return const _Spinner();
    }

    final access = ref.watch(projectorAccessProvider);
    return switch (access) {
      AsyncData(value: ProjectorAccess.granted) => child,
      AsyncData(value: ProjectorAccess.signedOut) => const _SignInCard(),
      AsyncData(value: ProjectorAccess.denied) => const _DeniedCard(),
      AsyncError() => ErrorCard(
        message:
            'Yetki kontrol edilemedi. Bağlantını kontrol edip tekrar dene.',
        actionLabel: 'Tekrar dene',
        onAction: () => ref.invalidate(projectorAccessProvider),
      ),
      _ => const _Spinner(),
    };
  }
}

class _Spinner extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: Palette.yellow));
}

class _GateCard extends StatelessWidget {
  const new({required this.title, required this.body, required this.action});

  final String title;
  final String body;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Sticker(
            shadow: Palette.yellow,
            shadowOffset: 8,
            radius: Radii.big,
            tiltDegrees: -1,
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: TextStyles.display.copyWith(
                    fontSize: 30,
                    color: Palette.ink,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  body,
                  style: TextStyles.ui.copyWith(
                    fontSize: 20,
                    color: Palette.inkMuted,
                  ),
                ),
                const SizedBox(height: 22),
                action,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SignInCard extends ConsumerStatefulWidget {
  const new();

  @override
  ConsumerState<_SignInCard> createState() => _SignInCardState();
}

class _SignInCardState extends ConsumerState<_SignInCard> {
  bool _busy = false;
  String? _failed;

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _failed = null;
    });
    try {
      await ref.read(staffAuthProvider).signInWithGoogle();
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _failed = e.code);
    } on Exception {
      if (mounted) setState(() => _failed = 'unknown');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _GateCard(
      title: 'Projeksiyon',
      body: _failed != null
          ? 'Giriş tamamlanamadı ($_failed). '
                'Açılan pencereyi kapatmadan tekrar dene.'
          : 'Görevli Google hesabınla giriş yap.',
      action: PrimaryButton(
        label: 'Google ile giriş yap',
        busy: _busy,
        shadow: Palette.ink,
        onPressed: _signIn,
      ),
    );
  }
}

class _DeniedCard extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _GateCard(
      title: 'Bu hesabın projeksiyon yetkisi yok',
      body: 'Yetkili bir görevli hesabıyla giriş yapmak için çıkış yap.',
      action: PrimaryButton(
        label: 'Çıkış yap',
        shadow: Palette.ink,
        onPressed: () => ref.read(staffAuthProvider).signOut(),
      ),
    );
  }
}
