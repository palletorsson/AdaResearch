// The tape wall: lay the first wall, 'december', from Palle's photo of his office wall (2026-11-16), when it is missing.
// The photo covers about 35 x 46 cm of wall (1088 x 1450 px; the 48 mm blue painter's tape is about 150 px across, so
// 3125 px to the metre): the ADA PRESENT strip, a clear piece with a red arrow under it, three blue squares with a
// clear plus and a clear circled dot between them, and two clear arrows below. Each piece's centre, length and turn
// were read off the photo (the blue pieces by colour, the clear ones by eye on enlarged crops) and are laid at real
// size near the middle of a 2.4 x 1.6 m wall painted the photo's warm off-white. The pieces are laid THROUGH the ops
// (ada_encyclopedia src/lib/tape-wall.ts applyOps, the same code the server runs), by 'palle-photo', so the record
// says where they came from; a wall that is already there is never laid again.
//
// Run from the repo root:
//   ../ada_encyclopedia/node_modules/.bin/tsx tools/tape_wall_seed.ts [--check] [--dry] [--file=<walls.json>] [--history=<dir>]
// --check  writes nothing: exit 0 when the december wall is there and the file reads back clean (its text is what the
//          contract writes for what it reads), else exit 1.
// --dry    prints the ops and what they would lay, writes nothing.
// --file / --history  seed another document (a test's copy) and keep the text it replaces there, never the truth's.
import {existsSync, mkdirSync, readFileSync, readdirSync, renameSync, unlinkSync, writeFileSync} from 'fs';
import {dirname, join} from 'path';
import {applyOps, cleanDoc, cleanOp, emptyDoc, PAINT, wallsText, type Op, type WallsDoc} from '../../ada_encyclopedia/src/lib/tape-wall';

const args = process.argv.slice(2);
const flag = (name: string) => args.includes(`--${name}`);
const value = (name: string) => args.find(a => a.startsWith(`--${name}=`))?.slice(name.length + 3);
for (const a of args) {
  if (!/^--(check|dry|file=.+|history=.+)$/.test(a)) { console.log(`unknown argument '${a}' (--check, --dry, --file=<path>, --history=<dir>)`); process.exit(2); }
}
const FILE = value('file') ?? 'commons/data/tape_wall/walls.json';
const HISTORY = value('history') ?? 'ada_run/tape_wall/history';
const BY = 'palle-photo';
const WALL = {id: 'december', title: 'December presentation', w: 2.4, h: 1.6, paint: PAINT};

// The photo, in its own pixels: centre [x, y], length along the tape and turn (degrees clockwise) as measured. A
// square's length is its two measured sides' ratio times the tape's 48 mm instead: the photo's lower half is
// magnified by its perspective (the squares measure 157-165 px across where 3125 px/m gives the tape 150), and a
// square should stay square. A blue piece's cut is the seed (of the first 30000) whose torn ends lean as the photo's do:
// the outward offset at the bottom corner minus the top's, start and end, in mm, read off the photo's outlines - the strip
// +3.2 / 0 (a 4 mm bite at the start), square 1 +0.5 / +1.1, square 2 +5.7 / +3.5, square 3 -6.5 / +1.2.
const PX_PER_M = 3125;
const ORIGIN = [1.037, 0.549];   // where the photo's top-left corner lies on the wall: the arrangement's middle on the wall's
const RED = '#841822';
type Laid = {id: string; tape: 'blue' | 'clear'; px: [number, number]; lenPx?: number; sides?: [number, number]; turn: number; cut: number; text?: string; symbol?: 'arrow' | 'plus' | 'dot'};
const PHOTO: Laid[] = [
  {id: 'ada-present', tape: 'blue', px: [422.5, 418.4], lenPx: 795, turn: 0.86, cut: 13648, text: 'ADA PRESENT'},
  {id: 'arrow-under-title', tape: 'clear', px: [400, 526.5], lenPx: 240, turn: 0, cut: 2207, symbol: 'arrow'},
  {id: 'square-1', tape: 'blue', px: [253.9, 904.6], sides: [165.2, 162.0], turn: 2, cut: 11527},
  {id: 'plus', tape: 'clear', px: [436, 924], lenPx: 163, turn: 356, cut: 4409, symbol: 'plus'},
  {id: 'square-2', tape: 'blue', px: [600.5, 958.1], sides: [157.3, 157.2], turn: 7.5, cut: 25693},
  {id: 'circled-dot', tape: 'clear', px: [757.5, 968], lenPx: 134, turn: 2.7, cut: 6607, symbol: 'dot'},
  {id: 'square-3', tape: 'blue', px: [901, 966.5], sides: [159.2, 157.8], turn: 14.6, cut: 26295},
  {id: 'arrow-left', tape: 'clear', px: [467, 1182.5], lenPx: 223, turn: 4.3, cut: 8807, symbol: 'arrow'},
  {id: 'arrow-right', tape: 'clear', px: [743, 1170], lenPx: 181, turn: 6, cut: 9901, symbol: 'arrow'},
];

const now = new Date().toISOString().replace(/\.\d+Z$/, 'Z');
const fail = (why: string): never => { console.log(why); process.exit(1); };

const before = existsSync(FILE) ? readFileSync(FILE, 'utf-8') : null;
let doc: WallsDoc = emptyDoc();
if (before !== null) {
  let raw: unknown;
  try { raw = JSON.parse(before); } catch (e) { fail(`${FILE} is not JSON (${(e as Error).message}); not touched`); }
  const c = cleanDoc(raw, now);
  if (!c.doc) fail(`${FILE} does not clean (${c.error}); not touched`);
  doc = c.doc!;
}
const readsBackClean = (text: string) => {
  const c = cleanDoc(JSON.parse(text), now);
  return !!c.doc && wallsText(c.doc) === text;
};
const there = doc.walls.find(w => w.id === WALL.id);

if (flag('check')) {
  if (!there) fail(`${FILE}: no '${WALL.id}' wall (run tools/tape_wall_seed.ts)`);
  if (!readsBackClean(before!)) fail(`${FILE} does not read back clean: its text is not what the contract writes for it`);
  console.log(`${FILE}: the '${WALL.id}' wall is there (${there!.pieces.length} pieces, ${there!.pieces.filter(p => p.state === 'on').length} on), revision ${doc.revision}; reads back clean`);
  process.exit(0);
}
if (there) {
  console.log(`${FILE}: the '${WALL.id}' wall is already there (${there.pieces.length} pieces); nothing laid`);
  process.exit(0);
}

const r4 = (v: number) => Math.round(v * 1e4) / 1e4;
const raw: unknown[] = [{op_id: `seed-${WALL.id}-wall`, op: 'wall', wall: WALL}];
for (const p of PHOTO) {
  const wid = p.tape === 'blue' ? 0.048 : 0.024;
  const piece: Record<string, unknown> = {
    id: p.id, tape: p.tape,
    at: [r4(ORIGIN[0] + p.px[0] / PX_PER_M), r4(ORIGIN[1] + p.px[1] / PX_PER_M)],
    len: r4(p.sides ? (wid * p.sides[0]) / p.sides[1] : p.lenPx! / PX_PER_M), wid, turn: p.turn, cut: p.cut,
  };
  if (p.text) piece.text = p.text;
  if (p.symbol) { piece.symbol = p.symbol; piece.ink = RED; }
  raw.push({op_id: `seed-${WALL.id}-${p.id}`, op: 'put', wall: WALL.id, piece});
}
const ops: Op[] = raw.map(r => {
  const c = cleanOp(r);
  if (!c.op) fail(`the seed's own op does not clean: ${c.error}`);
  return c.op!;
});
const out = applyOps(doc, ops, BY, now);
const refused = out.results.filter(r => !r.ok);
if (refused.length) fail(`not laid (nothing written): ${refused.map(r => r.error).join('; ')}`);
const text = wallsText(out.doc);
if (!readsBackClean(text)) fail('the seeded document would not read back clean (nothing written)');
const wall = out.doc.walls.find(w => w.id === WALL.id)!;
if (flag('dry')) {
  console.log(JSON.stringify(ops, null, 1));
  console.log(`would lay the '${WALL.id}' wall: ${wall.pieces.length} pieces, revision ${out.doc.revision} (nothing written)`);
  process.exit(0);
}

// the text it replaces is kept first (the store's discipline), then the new text goes in by a rename
if (before !== null) {
  mkdirSync(HISTORY, {recursive: true});
  writeFileSync(join(HISTORY, `walls-${now.replace(/[:]/g, '')}-seed.json`), before);
  const kept = readdirSync(HISTORY).filter(n => n.startsWith('walls-') && n.endsWith('.json')).sort();
  for (const n of kept.slice(0, Math.max(0, kept.length - 200))) unlinkSync(join(HISTORY, n));
}
mkdirSync(dirname(FILE), {recursive: true});
const tmp = `${FILE}.${process.pid}.tmp`;
writeFileSync(tmp, text);
renameSync(tmp, FILE);
const back = readFileSync(FILE, 'utf-8');
if (back !== text || !readsBackClean(back)) fail(`${FILE} was written but does not read back clean`);
console.log(`${FILE}: laid the '${WALL.id}' wall (${wall.pieces.length} pieces, by ${BY}), revision ${out.doc.revision}; reads back clean`);
