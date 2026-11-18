// The tape wall: lay the 'mindmap' wall (Palle, 2026-11-18: "a tape mind map with title and small symbols and the two
// magnifying glasses"). The talk's title in the middle, the eight sections of the December route in a ring round it
// (read clockwise from the upper left), a clear arrow from the middle to each, under each title its first line from
// the talk draft (doc/talks/2026-12_storyboard_of_edges.md), and small squares of blue carrying ARTIFACT symbols: works
// with a traced symbol and a 3D model, so the 3D glass turns them and the slide glass puts them on the section's slide.
// Each section's pieces share its id prefix (p01-...), which is how the slide glass gathers a slide.
//
// Through the API's ops (by 'claude-suggestion'), laid only when the wall is missing; applied to a copy first.
//   ../ada_encyclopedia/node_modules/.bin/tsx tools/tape_wall_mindmap.ts [--dry] [--sandbox=<id>] [--server=<url>]
import {applyOps, cleanDoc, cleanOp, cutOf, type Op, type PieceDraft, type TapeId, type WallsDoc} from '../../ada_encyclopedia/src/lib/tape-wall';

const args = process.argv.slice(2);
const value = (name: string) => args.find(a => a.startsWith(`--${name}=`))?.slice(name.length + 3);
for (const a of args) {
  if (!/^--(dry|sandbox=[a-z0-9_-]{2,64}|server=.+)$/.test(a)) { console.log(`unknown argument '${a}' (--dry, --sandbox=<id>, --server=<url>)`); process.exit(2); }
}
const DRY = args.includes('--dry');
const SERVER = value('server') ?? 'http://localhost:3003';
const SANDBOX = value('sandbox');
const q = SANDBOX ? `?sandbox=${SANDBOX}` : '';
const BY = 'claude-suggestion';
const WALL = {id: 'mindmap', title: 'Talk mind map: sections and works (18 Nov)', w: 3.0, h: 1.9, paint: '#e5d9c3'};

const lean = (id: string, most = 1.1) => ((cutOf(id) % 1000) / 1000 - 0.5) * 2 * most;
const pieces: PieceDraft[] = [];
const lay = (id: string, tape: TapeId, at: [number, number], len: number, wid: number, extra: Partial<PieceDraft> = {}, turn?: number) => {
  pieces.push({id, tape, at: [+at[0].toFixed(4), +at[1].toFixed(4)], len, wid, turn: (((turn ?? lean(id)) % 360) + 360) % 360, cut: cutOf(id),
    ink: tape === 'clear' ? '#841822' : '#1d2129', ...extra});
};

type Node = {n: number; title: string; say: string; works: string[]};
const NODES: Node[] = [
  {n: 1, title: 'P01 IMAGINE A POINT', say: "THE HAND'S LINE IS A STREAM OF POINTS", works: ['dark_sphere', 'grabbable_line']},
  {n: 2, title: 'P02 THE ORIGINAL QUESTION', say: 'A QUEER DESIRE FOR RULES', works: ['cellular_automata_3d_tree', 'Hilbert3D']},
  {n: 3, title: 'P03 THE TOOLS CHANGE THE RESEARCH', say: 'THIS IS TOO BIG', works: ['cube_scene', 'brick_wall_factory', 'ca_screen']},
  {n: 4, title: 'P04 ENTER THE VOID TOWER', say: 'SO WE ARRIVE LATE', works: ['mod_cardboard_box', 'mod_eu_pallet', 'exit_sign']},
  {n: 5, title: 'P05 READ IT THROUGH ITS INHABITANTS', say: 'THE GHOST STUDENT, THE GHOST TEACHER', works: ['AnimatedTree', 'branching_coral']},
  {n: 6, title: 'P06 INVESTIGATE THE EDGES', say: 'EDGE SEARCHING: STAY WITH THE DIFFERENCE', works: ['ca_bridge', 'mod_plastic_cone']},
  {n: 7, title: 'P07 DELEGATION AND RESPONSIBILITY', say: 'GIT CANNOT RESTORE ATTENTION', works: ['SpectrumVisualizer', 'NoiseColors3D']},
  {n: 8, title: 'P08 OFFER A BRANCHING WORLD', say: 'THE MUSEUM, HAUNTED BY WHAT IT COULD BECOME', works: ['pyramid', 'carousel_cake', 'mod_skateboard']},
];

const C: [number, number] = [1.5, 0.95], RX = 1.1, RY = 0.62, SQ = 0.07;
lay('centre', 'blue', C, 0.9, 0.06, {text: 'ADA RESEARCH - A STORYBOARD OF EDGES'});
lay('centre-note', 'masking', [C[0], C[1] + 0.055], 0.5, 0.022, {text: 'DECEMBER SEMINAR · 30 MIN'});
NODES.forEach((node, i) => {
  const a = ((-157.5 + i * 45) * Math.PI) / 180;
  const x = C[0] + RX * Math.cos(a), y = C[1] + RY * Math.sin(a);
  const id = `p0${node.n}`;
  lay(`${id}-strip`, 'blue', [x, y], 0.46, 0.045, {text: node.title});
  lay(`${id}-say`, 'washi', [x, y + 0.055], 0.44, 0.03, {text: node.say});
  const row = node.works.length, gap = 0.085;
  node.works.forEach((token, k) => {
    lay(`${id}-work-${k + 1}`, 'blue', [x + (k - (row - 1) / 2) * gap, y + 0.12], SQ, SQ, {artifact: token});
  });
  // the arrow from the middle out to the section, a little past halfway
  const ax = C[0] + 0.55 * (x - C[0]), ay = C[1] + 0.55 * (y - C[1]);
  const turn = (Math.atan2(y - C[1], x - C[0]) * 180) / Math.PI;
  lay(`${id}-from-centre`, 'clear', [ax, ay], 0.16, 0.024, {symbol: 'arrow'}, turn);
});

const ops: Op[] = [{op_id: 'mindmap-wall', op: 'wall', wall: WALL}, ...pieces.map(piece => ({op_id: `mindmap-${piece.id}`, op: 'put' as const, wall: WALL.id, piece}))];
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
  if (doc.walls.some(w => w.id === WALL.id)) { console.log(`the '${WALL.id}' wall is already there; nothing laid`); return; }
  const trial = applyOps(doc, cleaned, BY, now);
  const bad = trial.results.filter(x => !x.ok);
  if (bad.length) { for (const b of bad) console.log(`would be refused: ${b.op_id}: ${b.error}`); process.exit(1); }
  console.log(`${pieces.length} pieces on '${WALL.id}' (${WALL.w} x ${WALL.h} m), by ${BY}${SANDBOX ? `, in sandbox ${SANDBOX}` : ''}`);
  if (DRY) { for (const p of pieces) console.log(`  ${p.id.padEnd(18)} ${p.tape.padEnd(8)} [${p.at.join(', ')}] ${p.text ?? p.artifact ?? p.symbol ?? ''}`); return; }
  const post = await fetch(`${SERVER}/api/tape-wall/ops${q}`, {method: 'POST', headers: {'content-type': 'application/json'}, body: JSON.stringify({by: BY, ops: cleaned})});
  const out = await post.json() as {ok?: boolean; revision?: number; results?: {op_id: string; ok: boolean; error?: string}[]; error?: string};
  if (!post.ok || !out.ok) { console.log(`POST: ${post.status} ${out.error ?? JSON.stringify((out.results ?? []).filter(x => !x.ok))}`); process.exit(1); }
  console.log(`laid: revision ${out.revision}`);
};
main().catch(e => { console.log(String(e)); process.exit(1); });
