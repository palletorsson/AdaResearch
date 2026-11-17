// The badge coins: seed them, derive where each stands and what it shows, and check that the derivation is current.
// AUTHORED: commons/data/badges/coins.json (which coins, what each says and gives, where on the walk). DERIVED:
// commons/data/badges/path.json - each coin's number along the walk through the tower, its place, its two faces as SVG -
// the one file the game reads. The rules live in ada_encyclopedia src/lib/badge-coins.ts (derivePath, seedCoins,
// coinFace, coinBack); this tool reads the files, calls them and writes.
//
// Run from the repo root:
//   ../ada_encyclopedia/node_modules/.bin/tsx tools/badge_coins.ts            derive path.json and print a summary
//   ../ada_encyclopedia/node_modules/.bin/tsx tools/badge_coins.ts --seed     ADD the coins the tower implies to coins.json
//   ../ada_encyclopedia/node_modules/.bin/tsx tools/badge_coins.ts --check    write nothing; exit 1 when path.json is not
//                                                                              what the derivation gives, or a coin is invalid
// --coins=<file> / --path=<file> read and write another coins.json / path.json (a test's copy), never the truth's.
//
// Reads, never writes: commons/void/rooms.json, commons/data/artifact_timeline_walk.json, commons/modular/grammar.json,
// commons/modular/terms.json, commons/void/spine.json (seed only: a floor's sequence, by its MAP), and
// commons/data/stickers/readings.json and designs.json. Writes go through a temp file and a rename (a plain open of
// these files has failed with EINVAL on this machine).
import {existsSync, readFileSync, renameSync, writeFileSync} from 'fs';
import {
  coinsText, derivePath, pathText, seedCoins, type CoinsDoc, type GrammarOp, type TowerFloor, type Walk,
} from '../../ada_encyclopedia/src/lib/badge-coins';
import type {Layer} from '../../ada_encyclopedia/src/lib/stickers';
import type {Reading} from '../../ada_encyclopedia/src/lib/sticker-starter';

const args = process.argv.slice(2);
for (const a of args) {
  if (!/^--(seed|check|coins=.+|path=.+)$/.test(a)) { console.log(`unknown argument '${a}' (--seed, --check, --coins=<file>, --path=<file>)`); process.exit(2); }
}
const flag = (name: string) => args.includes(`--${name}`);
const value = (name: string) => args.find(a => a.startsWith(`--${name}=`))?.slice(name.length + 3);
if (flag('seed') && flag('check')) { console.log('--seed and --check: one at a time'); process.exit(2); }

const COINS = value('coins') ?? 'commons/data/badges/coins.json';
const PATH = value('path') ?? 'commons/data/badges/path.json';
const read = (file: string) => JSON.parse(readFileSync(file, 'utf-8'));
const write = (file: string, text: string) => {
  const tmp = `${file}.tmp-${process.pid}`;
  writeFileSync(tmp, text);
  renameSync(tmp, file);
};

const coinsRaw = readFileSync(COINS, 'utf-8');
const coins = JSON.parse(coinsRaw) as CoinsDoc;
const floors = read('commons/void/rooms.json').floors as TowerFloor[];
const walk = read('commons/data/artifact_timeline_walk.json').floors as Walk;
const grammar = read('commons/modular/grammar.json') as {operations: Record<string, GrammarOp>; spine: {sequence: string; root: string | null}[]};
const readings = read('commons/data/stickers/readings.json').readings as Reading[];
const designsList = read('commons/data/stickers/designs.json').designs as {id: string; layers: Layer[]}[];
const designs: Record<string, {layers: Layer[]}> = Object.fromEntries(designsList.map(d => [d.id, d]));

if (flag('seed')) {
  // the file is kept by hand: refuse to rewrite it when its text is not what the writer would write for what it holds
  if (coinsText(coins) !== coinsRaw.replace(/\r\n/g, '\n')) {
    console.log(`${COINS}: its text is not in the one-coin-per-line shape this tool writes (edited by hand?); not seeded. Put it back in that shape, or add the coins by hand.`);
    process.exit(1);
  }
  const terms = read('commons/modular/terms.json').terms;
  const spineFloors = read('commons/void/spine.json').floors as {map: string; sequence: string}[];
  const floorSequence = Object.fromEntries(spineFloors.map(f => [f.map, f.sequence]));
  const unmapped = floors.filter(f => !floorSequence[f.map]).map(f => f.map);
  if (unmapped.length) console.log(`note: ${unmapped.length} tower floor(s) have no sequence in commons/void/spine.json: ${unmapped.join(', ')}`);
  const {doc, added, said} = seedCoins({coins, floors, walk, spine: grammar.spine, ops: grammar.operations, terms, floorSequence, readings, designs: new Set(Object.keys(designs))});
  for (const s of said) console.log(`  ${s}`);
  if (!added.length) { console.log(`${COINS}: nothing to add (${coins.coins.length} coins)`); process.exit(0); }
  const by: Record<string, number> = {};
  for (const c of added) by[c.family] = (by[c.family] ?? 0) + 1;
  write(COINS, coinsText(doc));
  console.log(`${COINS}: added ${added.length} coins (${Object.entries(by).map(([f, n]) => `${f} ${n}`).join(', ')}); ${doc.coins.length} in all. Derive path.json next (no flag).`);
  process.exit(0);
}

const {doc, refusals} = derivePath({coins, floors, walk, ops: grammar.operations, readings, designs});
const text = pathText(doc);
if (refusals.length) {
  console.log(`${refusals.length} coin(s) refused:`);
  for (const r of refusals) console.log(`  ${r}`);
}
const current = existsSync(PATH) ? readFileSync(PATH, 'utf-8').replace(/\r\n/g, '\n') : null;
if (flag('check')) {
  const same = current === text;
  if (!same) console.log(current === null ? `${PATH} does not exist: derive it (no flag)` : `${PATH} is not what the derivation gives: derive it again (no flag)`);
  if (same && !refusals.length) console.log(`${PATH}: current, ${doc.count} coins`);
  process.exit(same && !refusals.length ? 0 : 1);
}
if (refusals.length) { console.log(`${PATH} not written: mend the coins above first`); process.exit(1); }
if (current !== text) write(PATH, text);
console.log(`${PATH}: ${current === text ? 'already current' : 'written'}, ${doc.count} coins, ${(text.length / 1024).toFixed(0)} KB`);
const fam: Record<string, number> = {};
for (const c of doc.coins) fam[c.family] = (fam[c.family] ?? 0) + 1;
console.log(`families: ${Object.entries(fam).map(([f, n]) => `${f} ${n}`).join(', ')}`);
const perFloor = new Map<string, string[]>();
for (const c of doc.coins) {
  const k = `${String(c.floor_index).padStart(3, ' ')} ${c.floor}`;
  perFloor.set(k, [...(perFloor.get(k) ?? []), `${c.label} ${c.family} ${c.name}${c.replaces ? ` (replaces ${c.replaces})` : ` (stop ${c.stop})`}${c.gives ? `, gives ${c.gives}` : ''}`]);
}
console.log(`floors: ${perFloor.size}`);
for (const [k, v] of perFloor) console.log(`  ${k}: ${v.join('; ')}`);
