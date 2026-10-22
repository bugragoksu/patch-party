import { z } from 'zod';
import { GameError } from './errors.js';

export const eventIdSchema = z.string().regex(/^[a-z0-9-]{3,64}$/);

export function parse<T>(schema: z.ZodType<T>, data: unknown): T {
  const result = schema.safeParse(data);
  if (!result.success) throw new GameError('invalid_argument');
  return result.data;
}
