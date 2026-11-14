// Arguments -> stickers: lay each hall's 'hanging_board' (commons/data/arguments/<hall>.json) into the sticker truth.
// The board is added to commons/data/stickers/boards.json if it is not there; its stickers and threads are laid ONCE,
// THROUGH THE OPS - cleaned and applied as the server applies them, exactly as tools/stickers_seed.ts lays the mind
// map - so they follow the rules every medium follows. A sticker or thread already there (or peeled, or cut) is never
// laid again; from then on the board changes by ops in any medium. The designs must exist first: the readings are in
// commons/data/stickers/readings.json and tools/stickers_seed.ts derives their designs.
// Run from the repo root:
//   ../ada_encyclopedia/node_modules/.bin/tsx tools/arguments_stickers.ts [--dry]
// --dry applies the ops in memory, reports what would be laid or refused, and writes nothing.
import {readFileSync, writeFileSync, renameSync, readdirSync} from 'fs';
import {
  applyOps, boardsText, cleanBoardsDoc, cleanDesignsDoc, cleanOp, cleanPlacementsDoc, emptyBoards, emptyPlacements,
  placementsText, upForTurn, type Op,
} from '../../ada_encyclopedia/src/lib/stickers';

const DIR = 'commons/data/stickers';
const ARGS = 'commons/data/arguments';
const dry = process.argv.includes('--dry');
const now = new Date().toISOString().replace(/\.\d+Z$/, 'Z');
const read = (name: string) => JSON.parse(readFileSync(`${DIR}/${name}`, 'utf-8'));
const write = (name: string, text: string) => {
  const tmp = `${DIR}/${name}.${process.pid}.tmp`;
  writeFileSync(tmp, text);
  renameSync(tmp, `${DIR}/${name}`);
};

const designs = cleanDesignsDoc(read('designs.json')).doc;
if (!designs) throw new Error('designs.json does not validate');
const bdoc = cleanBoardsDoc(read('boards.json') ?? emptyBoards()).doc!;
let pdoc = cleanPlacementsDoc(read('placements.json') ?? emptyPlacements(), now).doc!;
let boardsChanged = false;
let placementsChanged = false;

for (const file of readdirSync(ARGS).filter(f => f.endsWith('.json')).sort()) {
  const doc = JSON.parse(readFileSync(`${ARGS}/${file}`, 'utf-8'));
  const hb = doc.hanging_board;
  if (!hb) continue;
  if (!bdoc.boards.some(b => b.id === hb.board.id)) {
    const c = cleanBoardsDoc({boards: [...bdoc.boards, hb.board]});
    if (!c.doc) throw new Error(`${file} board: ${c.error}`);
    bdoc.boards = c.doc.boards;
    bdoc.revision += 1;
    boardsChanged = true;
    console.log(`boards.json: the board '${hb.board.id}' added`);
  }
  const clean = (raw: unknown) => { const c = cleanOp(raw, now); if (!c.op) throw new Error(`${file}: ${c.error}`); return c.op; };
  const ops: Op[] = [];
  for (const s of hb.stickers as {id: string; design: string; at: [number, number, number]; turn: number; size: number}[]) {
    if (pdoc.stickers.some(x => x.id === s.id)) continue;
    if (!designs.designs.some(d => d.id === s.design)) throw new Error(`${file}: no design ${s.design} - add its reading and run tools/stickers_seed.ts first`);
    ops.push(clean({op_id: `seed-${s.id}`.slice(0, 64), op: 'add', sticker: {id: s.id, design: s.design, host: {kind: 'board', id: hb.board.id}, at: s.at, n: [0, 0, 1],
      up: upForTurn(s.turn), size: s.size, z: 0, by: 'void-pass', t: now, state: 'on', moves: 0}}));
  }
  for (const th of hb.threads as {id: string; a: string; b: string; word: string; why?: string; colour?: string}[]) {
    if ((pdoc.threads ?? []).some(x => x.id === th.id)) continue;
    ops.push(clean({op_id: `seed-${th.id}`.slice(0, 64), op: 'tie', thread: {id: th.id, a: th.a, b: th.b, word: th.word, why: th.why, colour: th.colour}}));
  }
  if (!ops.length) { console.log(`${file}: nothing new to lay on '${hb.board.id}'`); continue; }
  const out = applyOps(pdoc, ops, 'void-pass', now, new Map(designs.designs.map(d => [d.id, d])), new Map(bdoc.boards.map(b => [b.id, b])));
  const failed = out.results.filter(r => !r.ok);
  for (const f of failed) console.log(`  not laid: ${f.op_id}: ${f.error}`);
  console.log(`${file}: ${ops.length - failed.length} of ${ops.length} ops applied on '${hb.board.id}'`);
  if (out.changed) { pdoc = out.doc; placementsChanged = true; }
}

if (dry) {
  console.log('dry: nothing written');
} else {
  if (boardsChanged) { write('boards.json', boardsText(bdoc)); console.log(`boards.json written (revision ${bdoc.revision})`); }
  if (placementsChanged) { write('placements.json', placementsText(pdoc)); console.log(`placements.json written (revision ${pdoc.revision})`); }
}
