import { createHash } from 'node:crypto';
import { logger } from 'firebase-functions/v2';
import { HttpsError, type CallableRequest } from 'firebase-functions/v2/https';
import { GameError, toHttpsError } from './errors.js';

/** Logs never carry names, codes or tokens (SEC-22); only a short uid hash. */
export function uidHash(uid: string | undefined): string | undefined {
  return uid ? createHash('sha256').update(uid).digest('hex').slice(0, 16) : undefined;
}

type Handler<T> = (request: CallableRequest<unknown>) => Promise<T>;

/**
 * Common wrapper for every callable: expected failures become HttpsError with a
 * stable `reason`; anything else is logged with its stack and returned as `internal`.
 */
export function guarded<T>(name: string, handler: Handler<T>): Handler<T> {
  return async (request) => {
    const started = Date.now();
    const base = { fn: name, uidHash: uidHash(request.auth?.uid) };
    try {
      const result = await handler(request);
      logger.info(`${name}_ok`, { ...base, latencyMs: Date.now() - started });
      return result;
    } catch (error) {
      const latencyMs = Date.now() - started;
      if (error instanceof GameError) {
        logger.info(`${name}_rejected`, { ...base, reason: error.reason, latencyMs });
        throw toHttpsError(error);
      }
      if (error instanceof HttpsError) throw error;
      logger.error(`${name}_failed`, { ...base, latencyMs, error: error instanceof Error ? error.stack : String(error) });
      throw new HttpsError('internal', 'internal', { reason: 'internal' });
    }
  };
}
