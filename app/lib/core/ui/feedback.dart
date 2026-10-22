import 'package:baglanti_agi/app/theme/tokens.dart';
import 'package:baglanti_agi/core/domain/failures.dart';
import 'package:baglanti_agi/core/ui/buttons.dart';
import 'package:baglanti_agi/core/ui/sticker.dart';
import 'package:flutter/material.dart';

/// "What happened + what to do" for every expected failure (04-design.md §4).
String failureMessage(GameFailure f) => switch (f) {
  JoinCodeInvalid() =>
    "Katılım kodu değişmiş. Projeksiyondaki QR'ı yeniden okut.",
  EventClosed() => 'Oyun şu an katılıma kapalı.',
  EventFull() => 'Oyun dolu. Görevlilere haber verebilirsin.',
  InvalidName() =>
    "Bu ad kullanılamıyor. 2-24 harf, rakam, boşluk ya da . ' - kullan.",
  NameTaken() => 'Bu ad alınmış. Seni ayırt edebilmemiz için küçük bir ek yap.',
  InvalidInterests() => 'En az 2, en fazla 3 ilgi alanı seç.',
  NotLive() => 'Oyun henüz başlamadı ya da bitti.',
  Disqualified() => 'Bu hesapla şu an bağlantı kurulamıyor.',
  Cooldown() => 'Biraz soluklan, birkaç saniye sonra tekrar dene.',
  RateLimited() => 'Çok fazla hatalı deneme. Bir dakika sonra tekrar dene.',
  ConnectionLimit() => 'Bağlantı sınırına ulaştın. Tebrikler!',
  RequestLimit() => 'Önce bekleyen isteğinin sonucunu bekle.',
  SelfScan() => 'Bu senin kendi kodun.',
  CodeInvalid() => 'Bu kod tanınmadı. Kodu kontrol edip tekrar dene.',
  TokenExpired() => 'Kod yenilendi. Bir kez daha okut.',
  AlreadyConnected() => 'Bu kişiyle zaten bağlısınız.',
  RequestExpired() => 'İsteğin süresi doldu.',
  NotAllowed() => 'Bu işlem için yetkin yok.',
  NotFound() => 'Aranan kayıt bulunamadı.',
  Declined() => 'Şu an olmadı. Başka biriyle tanışmaya devam et.',
  Offline() =>
    'Bağlantı yok gibi görünüyor. İnternetini kontrol edip tekrar dene.',
  Unknown() => 'Bir şeyler ters gitti. Tekrar dene.',
};

/// Recovery card shown instead of a red error screen.
class ErrorCard extends StatelessWidget {
  const new({
    required this.message,
    required this.actionLabel,
    required this.onAction,
    super.key,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Sticker(
            outline: Palette.red,
            shadow: Palette.red,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Bir şey ters gitti',
                  style: TextStyles.display.copyWith(
                    fontSize: 22,
                    color: Palette.ink,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  style: TextStyles.ui.copyWith(
                    color: Palette.inkMuted,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 18),
                PrimaryButton(
                  label: actionLabel,
                  onPressed: onAction,
                  shadow: Palette.ink,
                  height: 52,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void showFailure(BuildContext context, GameFailure failure) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Palette.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Palette.ink, width: Stroke.width),
        ),
        content: Text(
          failureMessage(failure),
          style: TextStyles.ui.copyWith(
            color: Palette.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
}
