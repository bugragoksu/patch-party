import 'dart:async';

import 'package:baglanti_agi/app/providers.dart';
import 'package:baglanti_agi/app/theme/tokens.dart';
import 'package:baglanti_agi/core/ui/buttons.dart';
import 'package:baglanti_agi/core/ui/sticker.dart';
import 'package:baglanti_agi/features/admin/application/admin_providers.dart';
import 'package:baglanti_agi/features/admin/presentation/admin_console.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Admin surface (T10, FR-30..33, NFR-06). Google sign-in, then the panel
/// only for holders of the `admin` custom claim (SEC-40). The server enforces
/// the same claim on every callable and rule; this gate is only UX.
class AdminPage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(adminAccessProvider);
    return switch (access) {
      AsyncData(value: AdminAccess.admin) => const AdminConsole(),
      AsyncData(value: AdminAccess.notAdmin) => const _NotAdmin(),
      AsyncData(value: AdminAccess.signedOut) => const _SignIn(),
      AsyncError() => _GateCard(
        title: 'Yetki kontrol edilemedi',
        body: 'Bağlantını kontrol edip tekrar dene.',
        actions: [
          PrimaryButton(
            label: 'Tekrar dene',
            shadow: Palette.ink,
            height: 52,
            onPressed: () => ref.invalidate(adminAccessProvider),
          ),
        ],
      ),
      _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
    };
  }
}

class _SignIn extends ConsumerStatefulWidget {
  const new();

  @override
  ConsumerState<_SignIn> createState() => _SignInState();
}

class _SignInState extends ConsumerState<_SignIn> {
  bool _busy = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(staffAuthProvider).signInWithGoogle();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(
        () => _error = e.code == 'popup-closed-by-user'
            ? 'Giriş penceresi kapatıldı.'
            : 'Giriş yapılamadı. Açılır pencerelere izin verip tekrar dene.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _GateCard(
      title: 'Yönetici girişi',
      body: 'Etkinlik ekibinin Google hesabıyla giriş yap.',
      error: _error,
      actions: [
        PrimaryButton(
          label: 'Google ile giriş yap',
          busy: _busy,
          shadow: Palette.ink,
          height: 52,
          onPressed: () => unawaited(_signIn()),
        ),
      ],
    );
  }
}

class _NotAdmin extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = ref.watch(authUserProvider).value?.email;
    return _GateCard(
      title: 'Yönetici yetkisi yok',
      body:
          '${email ?? 'Bu hesap'} yönetici olarak tanımlı değil. Yetki yeni '
          'verildiyse tekrar kontrol et; değilse başka bir hesapla gir.',
      actions: [
        PrimaryButton(
          label: 'Tekrar kontrol et',
          shadow: Palette.ink,
          height: 52,
          onPressed: () => ref.invalidate(adminAccessProvider),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => ref.read(staffAuthProvider).signOut(),
          style: OutlinedButton.styleFrom(
            foregroundColor: Palette.ink,
            minimumSize: const Size.fromHeight(48),
            side: const BorderSide(color: Palette.ink, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Radii.button),
            ),
          ),
          child: const Text('Çıkış yap'),
        ),
      ],
    );
  }
}

class _GateCard extends StatelessWidget {
  const new({
    required this.title,
    required this.body,
    required this.actions,
    this.error,
  });

  final String title;
  final String body;
  final List<Widget> actions;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Sticker(
              shadow: Palette.paper,
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: TextStyles.display.copyWith(
                      fontSize: 24,
                      color: Palette.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    body,
                    style: TextStyles.ui.copyWith(
                      color: Palette.inkMuted,
                      fontSize: 15,
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      error!,
                      style: TextStyles.ui.copyWith(
                        color: Palette.red,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  ...actions,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
