// The tape wall: lay the second wall, 'route', from Palle's first draft of the December presentation (2026-11-16, "Ada
// Research - A Storyboard of Edges"), as its "Preparation board" asks: eight large blue strips P01-P08 for the timed
// sections, the smaller pieces beneath each holding what to SAY, what to SHOW, what to ASK and its STATUS, and the
// arrows, returns and questions on separate pieces, so the relationships can change without rewriting every scene.
// The sections stand as a storyboard, two rows of four, read like a comic; the through-line (construct, encounter,
// investigate, reconfigure, share) runs beside the title; the questions to prepare as visual branches hang in a column
// of black gaffer tape on the right; a key at the bottom says which tape holds what. Every piece's words are short
// readings of the draft, not its text: the draft stays the source.
//
// The pieces go THROUGH the API's ops (POST /api/tape-wall/ops, by 'palle-draft'), so the store writes them with its
// history and the record says where they came from; the wall is laid only when it is missing (a laid wall is Palle's
// to move). Every op is cleaned and the whole set applied to a copy first (tape-wall.ts cleanOp, applyOps): one
// refused op stops the run before anything is sent.
//
// Run from the repo root (the encyclopedia's dev server on :3003):
//   ../ada_encyclopedia/node_modules/.bin/tsx tools/tape_wall_route.ts [--dry] [--sandbox=<id>] [--server=<url>]
// --dry          prints what it would lay, sends nothing.
// --sandbox=<id> lays it in a test's copy (ada_run/tape_wall/sandbox/<id>/walls.json), never the truth.
import {applyOps, cleanDoc, cleanOp, cutOf, type Op, type PieceDraft, type SymbolId, type TapeId, type WallsDoc} from '../../ada_encyclopedia/src/lib/tape-wall';

const args = process.argv.slice(2);
const value = (name: string) => args.find(a => a.startsWith(`--${name}=`))?.slice(name.length + 3);
for (const a of args) {
  if (!/^--(dry|sandbox=[a-z0-9_-]{2,64}|server=.+)$/.test(a)) { console.log(`unknown argument '${a}' (--dry, --sandbox=<id>, --server=<url>)`); process.exit(2); }
}
const DRY = args.includes('--dry');
const SERVER = value('server') ?? 'http://localhost:3003';
const SANDBOX = value('sandbox');
const q = SANDBOX ? `?sandbox=${SANDBOX}` : '';
const BY = 'palle-draft';
const WALL = {id: 'route', title: 'The route: a storyboard of edges (draft 16 Nov)', w: 3.1, h: 1.65, paint: '#e5d9c3'};

// a hand never lays tape quite straight: a small turn from the piece's own seed, within about a degree
const lean = (id: string, most = 1.1) => ((cutOf(id) % 1000) / 1000 - 0.5) * 2 * most;
const pieces: PieceDraft[] = [];
const lay = (id: string, tape: TapeId, at: [number, number], len: number, wid: number, text?: string, symbol?: SymbolId, turn?: number) => {
  const cut = cutOf(id);
  pieces.push({id, tape, at, len, wid, turn: ((turn ?? lean(id)) + 360) % 360, cut, ...(text ? {text} : {}), ...(symbol ? {symbol} : {}),
    ink: tape === 'clear' ? '#841822' : tape === 'gaffer' ? '#f2f0ea' : '#1d2129'});
};

// the title, the line under it, and the through-line beside it (masking words, clear arrows between)
lay('title', 'blue', [0.70, 0.11], 1.15, 0.06, 'ADA RESEARCH - A STORYBOARD OF EDGES');
lay('subtitle', 'masking', [0.47, 0.178], 0.66, 0.024, 'DECEMBER SEMINAR · 30 MIN · DRAFT 16 NOV');
const LINE: [string, number, number][] = [['CONSTRUCT', 1.47, 0.2], ['ENCOUNTER', 1.77, 0.2], ['INVESTIGATE', 2.08, 0.22], ['RECONFIGURE', 2.41, 0.23], ['SHARE', 2.7, 0.13]];
LINE.forEach(([word, x, len], i) => {
  lay(`line-${word.toLowerCase()}`, 'masking', [x, 0.11], len, 0.03, word);
  if (i < LINE.length - 1) lay(`line-arrow-${i + 1}`, 'clear', [(x + len / 2 + LINE[i + 1][1] - LINE[i + 1][2] / 2) / 2, 0.11], 0.05, 0.024, undefined, 'arrow', 0);
});

// the eight sections, two rows of four: a blue strip, its minutes, then say / show / ask / status beneath it
type Section = {id: string; title: string; mins: string; say: string; show: string; ask: string; status: string};
const SECTIONS: Section[] = [
  {id: 'p01', title: 'P01 IMAGINE A POINT', mins: '0-4 MIN', say: 'A POINT HAS NO SIZE, NO SURFACE', show: 'SPHERE, CAMERA, GRID - PASS THROUGH', ask: 'WHERE DOES THE WORLD BEGIN AND END?', status: 'RECORD, OR LABEL AS ILLUSTRATION'},
  {id: 'p02', title: 'P02 THE ORIGINAL QUESTION', mins: '4-7 MIN', say: 'RULES THAT MAKE BEAUTY AND DIFFERENCE', show: 'POINT TRACE LINE ... STICK LEVER TOY', ask: 'WHAT CAN A LINE BECOME?', status: 'ANIMATE THE TWO ROUTES'},
  {id: 'p03', title: 'P03 THE TOOLS CHANGE THE RESEARCH', mins: '7-11 MIN', say: 'MORE THAN I CAN PLAY THROUGH', show: '3-5 DATED IMAGES + ONE AI CYCLE', ask: 'WHAT DISAPPEARS IN COMPRESSION?', status: 'PICK SCREENSHOTS + ONE CYCLE'},
  {id: 'p04', title: 'P04 ENTER THE VOID TOWER', mins: '11-16 MIN', say: 'CARE UNIT - MODEL B ARRIVES', show: '5 MIN ROUTE - VR OR RECORDING', ask: 'WHAT DOES CARE MEAN HERE?', status: 'REHEARSE + RECORD THE ROUTE'},
  {id: 'p05', title: 'P05 READ IT THROUGH ITS INHABITANTS', mins: '16-20 MIN', say: 'FOLLOW A THING INTO ITS RELATIONS', show: 'UNITS, ONE ARTIFACT, THE KNOWLEDGE TREE', ask: 'WHERE ELSE WAS THIS PART USED?', status: 'ONE WORKING PATH - EYE UNITS PROPOSED'},
  {id: 'p06', title: 'P06 INVESTIGATE THE EDGES', mins: '20-24 MIN', say: 'INVESTIGATE WHAT LOSS MAKES POSSIBLE', show: 'THREE RESPONSES TO ONE SURFACE', ask: 'WHAT ELSE COULD THIS BODY BECOME?', status: 'A SCENARIO - ADD REAL RUNS'},
  {id: 'p07', title: 'P07 DELEGATION AND RESPONSIBILITY', mins: '24-27 MIN', say: 'THROUGHPUT AND THOUGHT-PUT', show: 'ANATOMY OF AN INTERVENTION', ask: 'LESS CONTROL, MORE LEARNING?', status: 'A CONCEPTUAL MAP'},
  {id: 'p08', title: 'P08 OFFER A BRANCHING WORLD', mins: '27-30 MIN', say: 'INHERIT, MODIFY, PLAY, RETURN', show: 'VR · WIKI · THREE.JS · BLENDER', ask: 'WHAT TOOLS MAKE THE TOOLS THAT MAKE US?', status: 'CHECK WHAT A VISITOR CAN DO'},
];
const COLS = [0.32, 0.86, 1.4, 1.94], ROWS = [0.36, 0.96];
SECTIONS.forEach((s, i) => {
  const cx = COLS[i % 4], y = ROWS[Math.floor(i / 4)];
  lay(`${s.id}-strip`, 'blue', [cx, y], 0.48, 0.056, s.title);
  lay(`${s.id}-mins`, 'masking', [cx - 0.145, y + 0.052], 0.17, 0.02, s.mins);
  lay(`${s.id}-say`, 'washi', [cx, y + 0.105], 0.46, 0.03, s.say);
  lay(`${s.id}-show`, 'yellow', [cx, y + 0.155], 0.46, 0.036, s.show);
  lay(`${s.id}-ask`, 'pink', [cx, y + 0.205], 0.46, 0.036, s.ask);
  lay(`${s.id}-status`, 'green', [cx - 0.03, y + 0.255], 0.4, 0.036, s.status);
  if (i % 4 < 3) lay(`${s.id}-next`, 'clear', [cx + 0.27, y], 0.05, 0.024, undefined, 'arrow', 0);
});
// the second row goes on from the first, and three returns the draft names
lay('p04-on', 'clear', [2.275, 0.36], 0.1, 0.024, 'P05', 'arrow', 0);
lay('p04-return', 'clear', [1.94, 0.665], 0.42, 0.026, 'THE BODY RETURNS IN P06 AND P08', 'both');
lay('p06-return', 'clear', [0.86, 1.265], 0.44, 0.026, 'BACK TO THE SURFACE OF P01', 'loop');
lay('p08-return', 'clear', [1.94, 1.265], 0.42, 0.026, 'RETURN TO THE POINT', 'loop');

// the questions to prepare as visual branches, after the thirty minutes
lay('questions', 'gaffer', [2.7, 0.36], 0.52, 0.036, 'QUESTIONS - VISUAL BRANCHES');
['WHAT IS THE CONTRIBUTION?', 'WHAT MAKES THIS QUEER?', 'IS QFEP FORMALISED?', 'IS MODEL B AN AUTONOMOUS AI?', 'WHAT DO YOU DO WHEN AI BUILDS?',
  'CAN THE WORLD CHANGE ITS RULES?', 'WHAT DOES ASSEMBLY THEORY ADD?', 'BEYOND INHERITED MEDIA?', 'WHAT CAN ANOTHER PERSON TAKE AWAY?']
  .forEach((text, i) => lay(`question-${i + 1}`, 'gaffer', [2.7, 0.43 + i * 0.052], 0.52, 0.026, text));

// the key, and what the draft says of the two walls
const KEY: [string, TapeId, number, number, SymbolId?][] = [
  ['SECTION', 'blue', 0.17, 0.16], ['SAY', 'washi', 0.34, 0.1], ['SHOW', 'yellow', 0.47, 0.11], ['ASK', 'pink', 0.6, 0.1],
  ['STATUS', 'green', 0.75, 0.13], ['RELATION', 'clear', 0.94, 0.17, 'arrow'], ['QUESTION', 'gaffer', 1.13, 0.15],
];
for (const [word, tape, x, len, symbol] of KEY) lay(`key-${word.toLowerCase()}`, tape, [x, 1.5], len, tape === 'blue' ? 0.04 : tape === 'clear' ? 0.024 : 0.026, word, symbol);
lay('two-walls', 'masking', [2.05, 1.5], 0.92, 0.024, 'THE OFFICE WALL AND THIS ONE - TWO ARRANGEMENTS OF THE SAME MATERIAL');

const ops: Op[] = [{op_id: 'route-wall', op: 'wall', wall: WALL}, ...pieces.map(piece => ({op_id: `route-${piece.id}`, op: 'put' as const, wall: WALL.id, piece}))];

const now = new Date().toISOString().replace(/\.\d+Z$/, 'Z');
const cleaned: Op[] = ops.map(o => {
  const c = cleanOp(o);
  if (!c.op) { console.log(`refused before sending: ${o.op_id}: ${c.error}`); process.exit(1); }
  return c.op!;
});

const main = async () => {
  const r = await fetch(`${SERVER}/api/tape-wall${q}`, {cache: 'no-store'});
  if (!r.ok) { console.log(`GET /api/tape-wall${q}: ${r.status} ${await r.text()}`); process.exit(1); }
  const c = cleanDoc(await r.json(), now);
  if (!c.doc) { console.log(`the walls do not clean: ${c.error}`); process.exit(1); }
  const doc: WallsDoc = c.doc;
  if (doc.walls.some(w => w.id === WALL.id)) { console.log(`the '${WALL.id}' wall is already there (${doc.walls.find(w => w.id === WALL.id)!.pieces.length} pieces); nothing laid`); return; }
  const trial = applyOps(doc, cleaned, BY, now);
  const bad = trial.results.filter(x => !x.ok);
  if (bad.length) { for (const b of bad) console.log(`would be refused: ${b.op_id}: ${b.error}`); process.exit(1); }
  console.log(`${pieces.length} pieces on '${WALL.id}' (${WALL.w} x ${WALL.h} m), by ${BY}${SANDBOX ? `, in sandbox ${SANDBOX}` : ''}`);
  if (DRY) { for (const p of pieces) console.log(`  ${p.id.padEnd(22)} ${p.tape.padEnd(8)} ${p.text ?? ''} ${p.symbol ?? ''}`); return; }
  const post = await fetch(`${SERVER}/api/tape-wall/ops${q}`, {method: 'POST', headers: {'content-type': 'application/json'}, body: JSON.stringify({by: BY, ops: cleaned})});
  const out = await post.json() as {ok?: boolean; revision?: number; results?: {op_id: string; ok: boolean; error?: string}[]; error?: string};
  if (!post.ok || !out.ok) { console.log(`POST: ${post.status} ${out.error ?? JSON.stringify((out.results ?? []).filter(x => !x.ok))}`); process.exit(1); }
  console.log(`laid: revision ${out.revision}`);
};
main().catch(e => { console.log(String(e)); process.exit(1); });
