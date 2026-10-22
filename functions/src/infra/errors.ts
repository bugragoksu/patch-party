import { HttpsError, type FunctionsErrorCode } from 'firebase-functions/v2/https';

/**
 * Stable machine-readable reasons. The client maps each one to a GameFailure
 * and a localized message (architecture §4.1); the HttpsError message is never shown.
 */
export const REASONS = {
  invalid_argument: 'invalid-argument',
  unauthenticated: 'unauthenticated',
  permission_denied: 'permission-denied',
  not_found: 'not-found',
  join_code_invalid: 'failed-precondition',
  event_closed: 'failed-precondition',
  event_full: 'resource-exhausted',
  invalid_name: 'invalid-argument',
  name_taken: 'already-exists',
  invalid_interests: 'invalid-argument',
  not_live: 'failed-precondition',
  disqualified: 'permission-denied',
  cooldown: 'resource-exhausted',
  rate_limited: 'resource-exhausted',
  connection_limit: 'resource-exhausted',
  request_limit: 'resource-exhausted',
  self_scan: 'invalid-argument',
  code_invalid: 'invalid-argument',
  token_invalid: 'failed-precondition',
  already_connected: 'already-exists',
  request_expired: 'deadline-exceeded',
  invalid_transition: 'failed-precondition',
} as const satisfies Record<string, FunctionsErrorCode>;

export type Reason = keyof typeof REASONS;

/** An expected, user-facing rejection. Logged at info level, never as an error. */
export class GameError extends Error {
  constructor(
    readonly reason: Reason,
    readonly details: Record<string, unknown> = {},
  ) {
    super(reason);
    this.name = 'GameError';
  }
}

export function toHttpsError(error: GameError): HttpsError {
  return new HttpsError(REASONS[error.reason], error.reason, { reason: error.reason, ...error.details });
}

/** Reasons that count towards the per-player failure rate limit (SEC-12). */
export const COUNTED_FAILURES: ReadonlySet<Reason> = new Set(['code_invalid', 'token_invalid', 'self_scan']);
