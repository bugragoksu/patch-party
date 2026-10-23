import { defineInt } from 'firebase-functions/params';
import { setGlobalOptions } from 'firebase-functions/v2';
import { onCall } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import * as adminHandlers from './handlers/admin.js';
import * as connectionHandlers from './handlers/connections.js';
import * as joinHandlers from './handlers/join.js';
import { rankLiveEvents } from './handlers/ranks.js';
import { guarded } from './infra/observability.js';

// ADR-0002: every write goes through these functions. Region matches Firestore.
setGlobalOptions({ region: 'europe-west3', maxInstances: 10, memory: '256MiB', timeoutSeconds: 10, concurrency: 80 });

// Warm instances only on event day: set HOT_MIN_INSTANCES=1 in functions/.env.<project> (ADR-0002).
const hotMinInstances = defineInt('HOT_MIN_INSTANCES', { default: 0 });
// invoker 'public' is explicit so every deploy (not only the first create)
// keeps callables reachable; auth is checked inside each handler.
const hot = { minInstances: hotMinInstances, enforceAppCheck: false, cors: true, invoker: 'public' as const };
const staff = { enforceAppCheck: false, cors: true, timeoutSeconds: 60, invoker: 'public' as const };

export const join = onCall(hot, guarded('join', joinHandlers.join));
export const requestConnection = onCall(hot, guarded('requestConnection', connectionHandlers.requestConnection));
export const respondToRequest = onCall(hot, guarded('respondToRequest', connectionHandlers.respondToRequest));
export const cancelRequest = onCall({ cors: true, invoker: 'public' }, guarded('cancelRequest', connectionHandlers.cancelRequest));

export const setEventState = onCall(staff, guarded('setEventState', adminHandlers.setEventState));
export const updateEventConfig = onCall(staff, guarded('updateEventConfig', adminHandlers.updateEventConfig));
export const moderatePlayer = onCall(staff, guarded('moderatePlayer', adminHandlers.moderatePlayer));
export const purgeEvent = onCall(
  { ...staff, timeoutSeconds: 300, memory: '512MiB' },
  guarded('purgeEvent', adminHandlers.purgeEvent),
);

export const computeRanks = onSchedule({ schedule: 'every 1 minutes', timeZone: 'Europe/Istanbul' }, rankLiveEvents);
