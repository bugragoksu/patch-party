import type { EventState } from '../domain/rules.js';

// Firestore document shapes. All timestamps are epoch milliseconds so the
// Dart client reads them without conversions.

export interface EventSettings {
  cooldownSec: number;
  tokenWindowSec: number;
  joinWindowSec: number;
  requestTtlSec: number;
  maxConnPerPlayer: number;
  maxPlayers: number;
  appCheckEnforce: boolean;
  displayName: string;
  subtitle: string;
  prizes: string[];
  features: { badges: boolean; playerRank: boolean };
}

export const DEFAULT_SETTINGS: EventSettings = {
  cooldownSec: 60,
  tokenWindowSec: 30,
  joinWindowSec: 300,
  requestTtlSec: 45,
  maxConnPerPlayer: 60,
  maxPlayers: 200,
  appCheckEnforce: false,
  displayName: 'Patch Party',
  subtitle: '',
  prizes: [],
  features: { badges: true, playerRank: true },
};

export interface EventDoc {
  name: string;
  state: EventState;
  liveStartAt: number | null;
  liveEndAt: number | null;
  settings: EventSettings;
  /** Results shown so far after the game ends: 0 none, 1 third, 2 second, 3 first. */
  reveal: number;
  updatedAt: number;
}

export interface OutgoingRequest {
  requestId: string;
  toUid: string;
  expiresAt: number;
}

export interface PlayerDoc {
  displayName: string;
  nameKey: string;
  nameHidden: boolean;
  interests: string[];
  playerCode: string;
  score: number;
  connectionCount: number;
  bridgeCount: number;
  clustersMet: string[];
  badges: string[];
  rank: number | null;
  rankTotal: number | null;
  rankedAt: number | null;
  lastConnectionAt: number | null;
  outgoingRequest: OutgoingRequest | null;
  disqualified: boolean;
  joinedAt: number;
}

export type RequestStatus = 'pending' | 'accepted' | 'declined' | 'expired' | 'cancelled';

export interface ConnectionRequestDoc {
  fromUid: string;
  toUid: string;
  fromName: string;
  fromInterests: string[];
  toName: string;
  toInterests: string[];
  status: RequestStatus;
  createdAt: number;
  expiresAt: number;
  respondedAt: number | null;
}

export interface ConnectionDoc {
  participants: [string, string];
  scannerUid: string;
  targetUid: string;
  names: Record<string, string>;
  points: number;
  bonus: number;
  questionKey: string;
  questionSeed: number;
  createdAt: number;
}

export interface RateLimitDoc {
  windowStart: number;
  failures: number;
  blockedUntil: number | null;
  lastFailureReason: string | null;
  totalFailures: number;
}
