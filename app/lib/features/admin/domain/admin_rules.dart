import 'package:baglanti_agi/core/domain/models.dart';

// Pure admin rules: no Firebase, no Flutter. The server stays the authority
// (functions/src/domain/rules.ts, handlers/admin.ts); these only shape the UI.

/// State changes offered in the panel. Mirrors `TRANSITIONS` on the server
/// minus `ended -> archived`, which only happens through `purgeEvent` (FR-33).
const Map<EventState, List<EventState>> adminTransitions = {
  EventState.draft: [EventState.lobby],
  EventState.lobby: [EventState.live, EventState.draft],
  EventState.live: [EventState.lobby, EventState.ended],
  EventState.ended: [EventState.live],
  EventState.archived: [],
};

List<EventState> allowedTransitions(EventState from) =>
    adminTransitions[from] ?? const [];

/// Only `lobby -> live` opens a timed window on the server.
bool needsDuration(EventState from, EventState to) =>
    from == EventState.lobby && to == EventState.live;

const defaultLiveDurationMin = 15;
const minLiveDurationMin = 1;
const maxLiveDurationMin = 120;

/// Parses the live duration field; null when outside the server range.
int? parseLiveDuration(String raw) {
  final v = int.tryParse(raw.trim());
  if (v == null || v < minLiveDurationMin || v > maxLiveDurationMin) {
    return null;
  }
  return v;
}

String stateLabel(EventState s) => switch (s) {
  EventState.draft => 'Taslak',
  EventState.lobby => 'Lobi',
  EventState.live => 'Canlı',
  EventState.ended => 'Bitti',
  EventState.archived => 'Arşiv',
};

/// Verb for the transition button ("Lobiyi aç", "Oyunu başlat" ...).
String transitionLabel(EventState from, EventState to) => switch ((from, to)) {
  (EventState.draft, EventState.lobby) => 'Lobiyi aç',
  (EventState.lobby, EventState.live) => 'Oyunu başlat',
  (EventState.lobby, EventState.draft) => 'Taslağa geri al',
  (EventState.live, EventState.lobby) => 'Lobiye döndür',
  (EventState.live, EventState.ended) => 'Oyunu bitir',
  (EventState.ended, EventState.live) => 'Oyunu yeniden aç',
  _ => '${stateLabel(to)} durumuna geç',
};

// ---------------------------------------------------------------------------
// Suspicious players (FR-31, SEC-13)

/// Thresholds for the review list. Kept in one place so they are easy to tune.
class SuspicionRules {
  const new({
    this.maxFailures = 5,
    this.secondsPerConnection = 30,
    this.minConnections = 5,
  });

  /// Failed scans (rateLimits.totalFailures) at or above this are flagged.
  final int maxFailures;

  /// Faster than one connection per this many seconds since joining is
  /// flagged.
  final int secondsPerConnection;

  /// Below this many connections the speed rule stays quiet (early noise).
  final int minConnections;
}

enum SuspicionReason { failures, tooFast }

String suspicionLabel(SuspicionReason r) => switch (r) {
  SuspicionReason.failures => 'çok hatalı deneme',
  SuspicionReason.tooFast => 'çok hızlı bağlantı',
};

List<SuspicionReason> suspicionReasons({
  required int connectionCount,
  required int failures,
  required int joinedAtMs,
  required int nowMs,
  SuspicionRules rules = const SuspicionRules(),
}) {
  final out = <SuspicionReason>[];
  if (failures >= rules.maxFailures) out.add(SuspicionReason.failures);
  if (connectionCount >= rules.minConnections && joinedAtMs > 0) {
    // At least one window, so a fresh join is not divided by ~zero.
    final elapsedSec = ((nowMs - joinedAtMs) / 1000).clamp(
      rules.secondsPerConnection.toDouble(),
      double.infinity,
    );
    final allowed = elapsedSec / rules.secondsPerConnection;
    if (connectionCount > allowed) out.add(SuspicionReason.tooFast);
  }
  return out;
}

// ---------------------------------------------------------------------------
// Settings (mirrors settingsInput in functions/src/handlers/admin.ts)

const maxPrizeLines = 3;

class IntRange {
  const new(this.min, this.max);
  final int min;
  final int max;
}

abstract final class SettingsLimits {
  static const cooldownSec = IntRange(0, 600);
  static const requestTtlSec = IntRange(10, 300);
  static const maxConnPerPlayer = IntRange(1, 500);
  static const maxPlayers = IntRange(1, 1000);
  static const displayNameMax = 40;
  static const subtitleMax = 80;
  static const prizeMax = 120;
}

enum SettingsField {
  displayName,
  subtitle,
  prizes,
  cooldownSec,
  requestTtlSec,
  maxConnPerPlayer,
  maxPlayers,
}

/// The editable form. Numbers stay as raw text until validated.
class SettingsDraft {
  const new({
    required this.displayName,
    required this.subtitle,
    required this.prizes,
    required this.cooldownSec,
    required this.requestTtlSec,
    required this.maxConnPerPlayer,
    required this.maxPlayers,
    required this.appCheckEnforce,
    required this.badges,
    required this.playerRank,
  });

  factory fromSettings(EventSettings s) => SettingsDraft(
    displayName: s.displayName,
    subtitle: s.subtitle,
    prizes: List.generate(
      maxPrizeLines,
      (i) => i < s.prizes.length ? s.prizes[i] : '',
    ),
    cooldownSec: '${s.cooldownSec}',
    requestTtlSec: '${s.requestTtlSec}',
    maxConnPerPlayer: '${s.maxConnPerPlayer}',
    maxPlayers: '${s.maxPlayers}',
    appCheckEnforce: s.appCheckEnforce,
    badges: s.badges,
    playerRank: s.playerRank,
  );

  final String displayName;
  final String subtitle;
  final List<String> prizes;
  final String cooldownSec;
  final String requestTtlSec;
  final String maxConnPerPlayer;
  final String maxPlayers;
  final bool appCheckEnforce;
  final bool badges;
  final bool playerRank;

  /// Field -> Turkish error. Empty means valid.
  Map<SettingsField, String> validate() {
    final errors = <SettingsField, String>{};
    final name = displayName.trim();
    if (name.isEmpty || name.length > SettingsLimits.displayNameMax) {
      errors[SettingsField.displayName] =
          '1-${SettingsLimits.displayNameMax} karakter olmalı.';
    }
    if (subtitle.trim().length > SettingsLimits.subtitleMax) {
      errors[SettingsField.subtitle] =
          'En fazla ${SettingsLimits.subtitleMax} karakter.';
    }
    if (prizes.length > maxPrizeLines ||
        prizes.any((p) => p.trim().length > SettingsLimits.prizeMax)) {
      errors[SettingsField.prizes] =
          'En fazla $maxPrizeLines satır, her biri '
          '${SettingsLimits.prizeMax} karakter.';
    }
    void range(SettingsField f, String raw, IntRange r) {
      final v = int.tryParse(raw.trim());
      if (v == null || v < r.min || v > r.max) {
        errors[f] = '${r.min}-${r.max} arası tam sayı.';
      }
    }

    range(SettingsField.cooldownSec, cooldownSec, SettingsLimits.cooldownSec);
    range(
      SettingsField.requestTtlSec,
      requestTtlSec,
      SettingsLimits.requestTtlSec,
    );
    range(
      SettingsField.maxConnPerPlayer,
      maxConnPerPlayer,
      SettingsLimits.maxConnPerPlayer,
    );
    range(SettingsField.maxPlayers, maxPlayers, SettingsLimits.maxPlayers);
    return errors;
  }

  /// The `settings` payload for `updateEventConfig`: only fields that differ
  /// from [current]. Call after [validate] returned no errors.
  Map<String, Object?> patchAgainst(EventSettings current) {
    final patch = <String, Object?>{};
    final name = displayName.trim();
    if (name != current.displayName) patch['displayName'] = name;
    final sub = subtitle.trim();
    if (sub != current.subtitle) patch['subtitle'] = sub;
    final lines = [
      for (final p in prizes)
        if (p.trim().isNotEmpty) p.trim(),
    ];
    if (!_sameList(lines, current.prizes)) patch['prizes'] = lines;
    void number(String key, String raw, int was) {
      final v = int.parse(raw.trim());
      if (v != was) patch[key] = v;
    }

    number('cooldownSec', cooldownSec, current.cooldownSec);
    number('requestTtlSec', requestTtlSec, current.requestTtlSec);
    number('maxConnPerPlayer', maxConnPerPlayer, current.maxConnPerPlayer);
    number('maxPlayers', maxPlayers, current.maxPlayers);
    if (appCheckEnforce != current.appCheckEnforce) {
      patch['appCheckEnforce'] = appCheckEnforce;
    }
    final features = <String, bool>{
      if (badges != current.badges) 'badges': badges,
      if (playerRank != current.playerRank) 'playerRank': playerRank,
    };
    if (features.isNotEmpty) patch['features'] = features;
    return patch;
  }
}

bool _sameList(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

// ---------------------------------------------------------------------------
// Health card (NFR-06)

/// Connections per minute between two counts; null without a previous sample.
double? connectionsPerMinute({
  required int? previousCount,
  required int? previousAtMs,
  required int count,
  required int atMs,
}) {
  if (previousCount == null || previousAtMs == null) return null;
  final minutes = (atMs - previousAtMs) / 60000;
  if (minutes <= 0) return null;
  final delta = count - previousCount;
  return delta < 0 ? 0 : delta / minutes;
}
