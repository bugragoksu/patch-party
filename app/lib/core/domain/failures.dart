/// Expected, user-facing failures. Each maps 1:1 to a server `reason`
/// (architecture §3.5, functions/src/infra/errors.ts).
sealed class GameFailure {
  const new();

  static GameFailure fromReason(
    String? reason, [
    Map<String, Object?>? details,
  ]) {
    return switch (reason) {
      'join_code_invalid' => const JoinCodeInvalid(),
      'event_closed' => const EventClosed(),
      'event_full' => const EventFull(),
      'invalid_name' => const InvalidName(),
      'name_taken' => NameTaken(details?['suggestion'] as String?),
      'invalid_interests' => const InvalidInterests(),
      'not_live' => const NotLive(),
      'disqualified' => const Disqualified(),
      'cooldown' => Cooldown(_retryAt(details)),
      'rate_limited' => RateLimited(_retryAt(details)),
      'connection_limit' => const ConnectionLimit(),
      'request_limit' => const RequestLimit(),
      'self_scan' => const SelfScan(),
      'code_invalid' => const CodeInvalid(),
      'token_invalid' => const TokenExpired(),
      'already_connected' => const AlreadyConnected(),
      'request_expired' => const RequestExpired(),
      'permission_denied' || 'unauthenticated' => const NotAllowed(),
      'not_found' => const NotFound(),
      _ => const Unknown(),
    };
  }

  static DateTime? _retryAt(Map<String, Object?>? details) {
    final ms = details?['retryAt'];
    return ms is num ? DateTime.fromMillisecondsSinceEpoch(ms.toInt()) : null;
  }
}

class JoinCodeInvalid extends GameFailure {
  const new();
}

class EventClosed extends GameFailure {
  const new();
}

class EventFull extends GameFailure {
  const new();
}

class InvalidName extends GameFailure {
  const new();
}

class NameTaken extends GameFailure {
  const new(this.suggestion);
  final String? suggestion;
}

class InvalidInterests extends GameFailure {
  const new();
}

class NotLive extends GameFailure {
  const new();
}

class Disqualified extends GameFailure {
  const new();
}

class Cooldown extends GameFailure {
  const new(this.retryAt);
  final DateTime? retryAt;
}

class RateLimited extends GameFailure {
  const new(this.retryAt);
  final DateTime? retryAt;
}

class ConnectionLimit extends GameFailure {
  const new();
}

class RequestLimit extends GameFailure {
  const new();
}

class SelfScan extends GameFailure {
  const new();
}

class CodeInvalid extends GameFailure {
  const new();
}

class TokenExpired extends GameFailure {
  const new();
}

class AlreadyConnected extends GameFailure {
  const new();
}

class RequestExpired extends GameFailure {
  const new();
}

class NotAllowed extends GameFailure {
  const new();
}

class NotFound extends GameFailure {
  const new();
}

class Offline extends GameFailure {
  const new();
}

class Unknown extends GameFailure {
  const new();
}

/// Expected outcomes travel as values; programmer errors stay exceptions.
sealed class Result<T> {
  const new();
}

class Ok<T> extends Result<T> {
  const new(this.value);
  final T value;
}

class Err<T> extends Result<T> {
  const new(this.failure);
  final GameFailure failure;
}
