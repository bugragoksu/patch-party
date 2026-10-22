// Copies the shared catalog into the functions source tree so it ships with the deploy.
import { copyFileSync, mkdirSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const target = resolve(root, 'src/generated/interests.json');
mkdirSync(dirname(target), { recursive: true });
copyFileSync(resolve(root, '../shared/catalog/interests.json'), target);
