// The cardboard constructions' rules and geometry through the contract itself (ada_encyclopedia/src/lib/stickers.ts),
// on the same files the GDScript port reads, for comparison number for number (tools/probes/stickers_cardboard_parity.py
// runs both sides and compares).
//
//   ops:      what the server stores. applyOps(cleanPlacementsDoc(base), ops, 'vr:parity', now, designs, boards, walls),
//             the boards and the walls read as stickers-store.ts reads them (cleanBoardsDoc; wallsOf(cleanConstructionsDoc)
//             WITHOUT the boards). The ops are given raw, as the README's runner gives them (the server cleans them first:
//             cleanOp; the fixture's ops are written as cleanOp leaves them). The twin of tools/probes/stickers_apply_ops.gd.
//   geometry: wallPoint, wallYaw, drawnWallThreads (pinOf, threadCurve), drawnStrokes, strokeZ, wallsOf, cleanBoard,
//             cleanConstructionsDoc (with and without the boards) and cleanStroke, written as
//             tools/probes/stickers_cardboard_geometry.gd writes them.
//   over:     a thread never passes through cardboard: wallLines, drawnWallThreads' over, threadPieces (pieces, tag, each
//             piece's control point and middle, the tag's point), overBoard on every thread drawn on one board, the cases'
//             `over` (named overWalls, overBoard and threadPieces cases) and the constants every medium draws with, written
//             as stickers_cardboard_geometry.gd --mode=over writes them; and THE PROPERTY (`property`, the contract's
//             alone): every drawn piece of every thread between walls, and of every thread on one cardboard board, sampled
//             every 0.4 mm against every wall's cardboard, counted per construction and per board - a thread fails when a
//             sample lies 0.1 mm or more inside cardboard, unless a pin of it lies on a face pressed against another wall.
//
//   ../ada_encyclopedia/node_modules/.bin/tsx tools/probes/stickers_cardboard_runner.ts ops <base> <ops> <designs> <out> [<boards> | -] [<constructions>]
//   ../ada_encyclopedia/node_modules/.bin/tsx tools/probes/stickers_cardboard_runner.ts geometry <placements> <designs> <boards> <constructions> <cases | -> <out>
//   ../ada_encyclopedia/node_modules/.bin/tsx tools/probes/stickers_cardboard_runner.ts over <placements> <designs> <boards> <constructions> <cases | -> <out>
//
// Reads its inputs, writes only <out>; point it at copies of commons/data/stickers/*.json.
import fs from 'node:fs';
import {
  applyOps, cleanBoard, cleanBoardsDoc, cleanConstructionsDoc, cleanDesignsDoc, cleanPlacementsDoc, cleanStroke, drawnStrokes,
  drawnThreads, drawnWallThreads, overBoard, overWalls, pinOf, strokeZ, threadCurve, threadPieces, twoSided, wallLines, wallPoint, wallYaw, wallsOf,
  CARDBOARD, MITER_LIMIT, PEN_COLOUR_NAMES, PEN_COLOURS, PEN_LIST, PENS, STROKE_DOT, STROKE_LIFT, STROKE_POINTS, STROKE_STEP, THREAD_CLEAR, THREAD_OVER,
  type Board, type Construction, type Design, type Op, type Placed, type PlacementsDoc, type Thread, type Vec3, type WallLine,
} from '../../../ada_encyclopedia/src/lib/stickers';

const NOW = '2026-11-13T12:00:00Z';
const BY = 'vr:parity';
const SAMPLES = 16;
const read = (p: string): unknown => JSON.parse(fs.readFileSync(p, 'utf8'));

function designsOf(p: string): Map<string, Design> {
  const c = cleanDesignsDoc(read(p));
  if (!c.doc) throw new Error(`designs: ${c.error}`);
  return new Map(c.doc.designs.map(d => [d.id, d]));
}
function boardsOf(p: string): Board[] {
  const c = cleanBoardsDoc(read(p));
  if (!c.doc) throw new Error(`boards: ${c.error}`);
  return c.doc.boards;
}

function ops(args: string[]): void {
  const [basePath, opsPath, designsPath, outPath, boardsPath, consPath] = args;
  const base = cleanPlacementsDoc(read(basePath), NOW);
  if (!base.doc) throw new Error(`base: ${base.error}`);
  const boards = boardsPath && boardsPath !== '-' ? new Map(boardsOf(boardsPath).map(b => [b.id, b])) : undefined;
  let walls: Map<string, string> | undefined;
  if (consPath) {
    const c = cleanConstructionsDoc(read(consPath));
    if (!c.doc) throw new Error(`constructions: ${c.error}`);
    walls = wallsOf(c.doc);
  }
  const out = applyOps(base.doc, read(opsPath) as Op[], BY, NOW, designsOf(designsPath), boards, walls);
  fs.writeFileSync(outPath, JSON.stringify(out));
  const refused = out.results.filter(r => !r.ok).length, skipped = out.results.filter(r => r.ok && r.skipped).length;
  console.log(`stickers_cardboard_runner ops: ${out.results.length} results (${refused} refused, ${skipped} skipped), changed ${out.changed}, revision ${out.doc.revision}, threads ${out.doc.threads.length}, strokes ${out.doc.strokes?.length ?? 0}, walls ${walls ? walls.size : 'none'}`);
}

type Named = {name: string; raw: unknown};
function geometry(args: string[]): void {
  const [docPath, designsPath, boardsPath, consPath, casesPath, outPath] = args;
  const doc = read(docPath) as PlacementsDoc;
  const designs = designsOf(designsPath);
  const rawBoards = ((read(boardsPath) as {boards?: unknown[]}).boards ?? []) as Record<string, unknown>[];
  const list = boardsOf(boardsPath);
  const boards = new Map(list.map(b => [b.id, b]));
  const cases = (casesPath === '-' ? {} : read(casesPath)) as {boards?: Named[]; constructions?: Named[]; strokes?: Named[]};
  const cleanBoards: Record<string, unknown> = {};
  for (const raw of rawBoards) cleanBoards[`file:${raw && typeof raw === 'object' ? String(raw.id ?? '') : '?'}`] = cleanBoard(raw).board ?? null;
  for (const e of cases.boards ?? []) cleanBoards[e.name] = cleanBoard(e.raw).board ?? null;
  const consRaw = read(consPath);
  const cleanCons: Record<string, unknown> = {file: {plain: cleanConstructionsDoc(consRaw), boards: cleanConstructionsDoc(consRaw, boards)}};
  for (const e of cases.constructions ?? []) cleanCons[e.name] = {plain: cleanConstructionsDoc(e.raw), boards: cleanConstructionsDoc(e.raw, boards)};
  const cleanStrokes: Record<string, unknown> = {};
  for (const s of doc.strokes ?? []) cleanStrokes[`file:${s.id}`] = cleanStroke(s, NOW);
  for (const e of cases.strokes ?? []) cleanStrokes[e.name] = cleanStroke(e.raw, NOW);
  const readCons = cleanConstructionsDoc(consRaw);
  if (!readCons.doc) throw new Error(`constructions: ${readCons.error}`);
  const cons = readCons.doc;
  const walls = wallsOf(cons);
  const outCons: Record<string, unknown> = {};
  for (const c of cons.constructions) {
    const tables = new Map(c.tables.map(t => [t.id, t]));
    const wallRows = c.walls.map(w => {
      const t = tables.get(w.table), b = boards.get(w.board);
      const points: Vec3[] = [], pins: {id: string; at: Vec3}[] = [];
      if (b && t) {
        const hw = b.w / 2, hh = b.h / 2;
        for (const p of [[0, 0, 0], [-hw, -hh, 0], [hw, -hh, 0], [hw, hh, 0], [-hw, hh, 0], [0, 0, -CARDBOARD], [0.1234, -0.2345, 0.5], [-0.3, 0.25, -CARDBOARD - STROKE_LIFT]] as Vec3[]) {
          points.push(wallPoint(t, w, b, p));
        }
        for (const s of doc.stickers) {
          if (s.host.kind === 'board' && s.host.id === w.board) pins.push({id: s.id, at: wallPoint(t, w, b, pinOf(s, designs.get(s.design)))});
        }
      }
      return {board: w.board, table: w.table, yaw: t ? wallYaw(t, w) : null, points, pins};
    });
    const threads = drawnWallThreads(doc, c, boards, designs).map(e => {
      const cv = threadCurve(e.p, e.q);
      return {id: e.thread.id, a: e.a.id, b: e.b.id, p: e.p, q: e.q, c: cv.c, at: Array.from({length: SAMPLES + 1}, (_, i) => cv.at(i / SAMPLES))};
    });
    outCons[c.id] = {walls: wallRows, threads};
  }
  const outStrokes: Record<string, unknown> = {};
  for (const b of list) {
    const all = drawnStrokes(doc, b.id);
    const c = cons.constructions.find(x => x.id === walls.get(b.id));
    const w = c?.walls.find(x => x.board === b.id), t = w ? c?.tables.find(x => x.id === w.table) : undefined;
    const ends = w && t ? all.map(s => {
      const z = strokeZ(s.face), p0 = s.points[0], pn = s.points[s.points.length - 1];
      return {id: s.id, face: s.face, first: wallPoint(t, w, b, [p0[0], p0[1], z]), last: wallPoint(t, w, b, [pn[0], pn[1], z])};
    }) : [];
    outStrokes[b.id] = {front: drawnStrokes(doc, b.id, 'front').map(s => s.id), back: drawnStrokes(doc, b.id, 'back').map(s => s.id), all: all.map(s => s.id), ends};
  }
  fs.writeFileSync(outPath, JSON.stringify({clean: {boards: cleanBoards, constructions: cleanCons, strokes: cleanStrokes}, walls_of: Object.fromEntries(walls),
    stroke_z: {front: strokeZ('front'), back: strokeZ('back')}, constructions: outCons, strokes: outStrokes}));
  console.log(`stickers_cardboard_runner geometry: ${cons.constructions.length} constructions, ${Object.keys(cleanStrokes).length} strokes cleaned`);
}

// ---- over: a thread never passes through cardboard ----

type At = Vec3 | {board: string; at: Vec3};
type OverCases = {
  walls?: {name: string; construction?: string; p: At; q: At; walls?: (string | WallLine)[]}[];
  boards?: {name: string; p: Vec3; q: Vec3; board: string | Pick<Board, 'w' | 'h' | 'stock'>}[];
  pieces?: {name: string; p: Vec3; q: Vec3; over?: Vec3[]}[];
};

// a thread as a medium draws it: pins, the points over the walls, its pieces, the tag piece, each piece's control point
// and middle, the tag's point
function row(t: Thread, a: Placed, b: Placed, p: Vec3, q: Vec3, over: Vec3[]) {
  const pc = threadPieces(p, q, over);
  const curves = pc.pieces.map(([x, y]) => threadCurve(x, y));
  const mids = curves.map(cv => cv.at(0.5));
  return {id: t.id, a: a.id, b: b.id, p, q, over, pieces: pc.pieces, tag: pc.tag, cs: curves.map(cv => cv.c), mids, tag_at: mids[pc.tag]};
}

// ---- THE PROPERTY: what is drawn stays out of the cardboard (as tests/stickers/cardboard.test.ts holds it) ----
// Every drawn piece (threadPieces) sampled every 0.4 mm (threadCurve at u = i / n, n = max(64, |b - a| / 0.4 mm));
// a sample is IN a wall's cardboard when the least of its four margins - along the wall from its end, out of the
// cardboard's middle to a face, up from the bottom edge, down from the top edge - is SEEN (0.1 mm) or more. A thread
// FAILS when any sample is in, unless one of its pins lies on a face PRESSED against another wall (within SEEN of that
// wall's cardboard): such a sticker cannot be reached without passing through cardboard. THE RULE'S KNOWN LIMIT:
// walls that cross, meet at a joint (a T, a V, a corner of unequal heights) or stand back to back with less than
// CLOSE_GAP (4 mm) between them (README, "A thread never passes through cardboard"): the points over one can fall
// inside the other. A sample inside one of THOSE walls is counted apart (close_through), never a pass for a sample
// inside any other wall. The property is the contract's, held here
// on the contract's answers; the parity holds the port to those answers number for number.
const SEEN = 1e-4, STEP = 0.0004;
type Slab = {id: string; hw: number; mx: number; mz: number; ex: number; ez: number; nx: number; nz: number; bottom: number; top: number};
const slabsOf = (lines: Iterable<[string, WallLine]>): Slab[] => [...lines].flatMap(([id, w]) => {
  const hw = Math.hypot(w.b[0] - w.a[0], w.b[1] - w.a[1]) / 2;
  if (!(hw > 0)) return [];   // a wall of no length has no cardboard
  return [{id, hw, mx: (w.a[0] + w.b[0]) / 2, mz: (w.a[1] + w.b[1]) / 2, ex: (w.b[0] - w.a[0]) / (2 * hw), ez: (w.b[1] - w.a[1]) / (2 * hw),
    nx: w.n[0], nz: w.n[1], bottom: w.bottom, top: w.top}];
});
// how far a point lies inside the cardboard of the deepest of the slabs (> 0 inside), and which; -1 and '' far from all
function depthIn(v: Vec3, slabs: Slab[]): [number, string] {
  let deep = -1, at = '';
  for (const s of slabs) {
    const x = (v[0] - s.mx) * s.ex + (v[2] - s.mz) * s.ez, z = (v[0] - s.mx) * s.nx + (v[2] - s.mz) * s.nz;
    const d = Math.min(s.hw - Math.abs(x), CARDBOARD / 2 - Math.abs(z), v[1] - s.bottom, s.top - v[1]);
    if (d > deep) { deep = d; at = s.id; }
  }
  return [deep, at];
}
// the deepest any sample of the pieces goes into the slabs: [depth, wall, piece]
function deepestOf(pieces: [Vec3, Vec3][], slabs: Slab[]): [number, string, number] {
  let worst: [number, string, number] = [-1, '', -1];
  pieces.forEach(([a, b], k) => {
    const cv = threadCurve(a, b), n = Math.max(64, Math.ceil(Math.hypot(b[0] - a[0], b[1] - a[1], b[2] - a[2]) / STEP));
    for (let i = 0; i <= n; i++) {
      const [d, at] = depthIn(cv.at(i / n), slabs);
      if (d > worst[0]) worst = [d, at, k];
    }
  });
  return worst;
}
type Held = {threads: number; over_a_wall: number; plain_through: number; through: number; pressed: number; pressed_through: number;
  close_through: number; deepest_mm: number | null; close: string[];
  failing: {thread: string; a: string; b: string; wall: string; piece: number; of: number; depth_mm: number}[]};
const held = (close: string[] = []): Held => ({threads: 0, over_a_wall: 0, plain_through: 0, through: 0, pressed: 0, pressed_through: 0, close_through: 0,
  deepest_mm: null, close, failing: []});
// Walls too close for the rule: two walls whose cardboard's middles come within CARDBOARD + CLOSE_GAP of each other
// anywhere over a common height - crossing, back to back, at a T or a V - unless they meet only end to end (each at its
// own end, in a line or at a corner) with tops within THREAD_OVER of each other. Joints of equal heights at a right
// angle mostly hold; they are counted apart all the same (the rule is not held to joints).
const CLOSE_GAP = 0.004, CLOSE_END = 0.01, CLOSE_STEP = 0.002;
function tooClose(slabs: Slab[]): Set<string> {
  const out = new Set<string>();
  for (const A of slabs) {
    for (const B of slabs) {
      if (A === B || Math.max(A.bottom, B.bottom) >= Math.min(A.top, B.top)) continue;
      let close = false, endToEnd = true;
      const n = Math.max(1, Math.ceil((2 * A.hw) / CLOSE_STEP));
      for (let i = 0; i <= n; i++) {
        const x = -A.hw + (2 * A.hw * i) / n, px = A.mx + A.ex * x, pz = A.mz + A.ez * x;
        const tb = Math.max(-B.hw, Math.min(B.hw, (px - B.mx) * B.ex + (pz - B.mz) * B.ez));
        if (Math.hypot(px - (B.mx + B.ex * tb), pz - (B.mz + B.ez * tb)) >= CARDBOARD + CLOSE_GAP) continue;
        close = true;
        if (Math.abs(x) < A.hw - CLOSE_END || Math.abs(tb) < B.hw - CLOSE_END) endToEnd = false;
      }
      if (close && (!endToEnd || Math.abs(A.top - B.top) > THREAD_OVER)) { out.add(A.id); out.add(B.id); }
    }
  }
  return out;
}
const mm = (v: number) => Math.round(v * 1e6) / 1e3;
// one thread held to the property: its pins, its points, its pieces, the slabs it must keep out of, and for each pin the
// slabs a pressed face would lie against (every slab but the pin's own wall's)
function hold(h: Held, id: string, a: Placed, b: Placed, p: Vec3, q: Vec3, over: Vec3[], slabs: Slab[], pOthers: Slab[], qOthers: Slab[]): void {
  const pieces = threadPieces(p, q, over).pieces;
  const pressed = depthIn(p, pOthers)[0] > -SEEN || depthIn(q, qOthers)[0] > -SEEN;
  h.threads++;
  if (over.length) h.over_a_wall++;
  if (deepestOf([[p, q]], slabs)[0] >= SEEN) h.plain_through++;   // the negative: the one curve between the same pins
  if (pressed) {                                                   // (measured against every wall, as it always was)
    h.pressed++;
    if (deepestOf(pieces, slabs)[0] >= SEEN) h.pressed_through++;
    return;
  }
  const close = new Set(h.close), apart = close.size ? slabs.filter(s => !close.has(s.id)) : slabs;
  const [deep, wall, piece] = deepestOf(pieces, apart);   // held strictly against every wall that is not too close
  h.deepest_mm = h.deepest_mm === null ? mm(Math.max(deep, 0)) : Math.max(h.deepest_mm, mm(Math.max(deep, 0)));
  if (deep >= SEEN) {
    h.through++;
    if (h.failing.length < 5) h.failing.push({thread: id, a: a.id, b: b.id, wall, piece, of: pieces.length, depth_mm: mm(deep)});
  } else if (close.size && deepestOf(pieces, slabs.filter(s => close.has(s.id)))[0] >= SEEN) {
    h.close_through++;   // through a wall too close to another: the known limit, counted apart
  }
}

function overMode(args: string[]): void {
  const [docPath, designsPath, boardsPath, consPath, casesPath, outPath] = args;
  const doc = read(docPath) as PlacementsDoc;
  const designs = designsOf(designsPath);
  const list = boardsOf(boardsPath);
  const boards = new Map(list.map(b => [b.id, b]));
  const cases = (casesPath === '-' ? {} : read(casesPath)) as {over?: OverCases};
  const readCons = cleanConstructionsDoc(read(consPath));
  if (!readCons.doc) throw new Error(`constructions: ${readCons.error}`);
  const cons = readCons.doc;
  const byCons = new Map(cons.constructions.map(c => [c.id, c]));
  const outCons: Record<string, unknown> = {};
  const property = {constructions: {} as Record<string, Held>, boards: {} as Record<string, Held>};
  let nThreads = 0, nOver = 0, nBoard = 0;
  for (const c of cons.constructions) {
    const drawn = drawnWallThreads(doc, c, boards, designs);
    const rows = drawn.map(e => row(e.thread, e.a, e.b, e.p, e.q, e.over));
    nThreads += rows.length;
    nOver += rows.filter(r => r.over.length).length;
    const lines = wallLines(c, boards);
    outCons[c.id] = {lines: Object.fromEntries(lines), threads: rows};
    // the property: every thread between its walls against every wall of it; a pin pressed against a wall not its own
    const slabs = slabsOf(lines), others = (s: Placed) => slabs.filter(x => !(s.host.kind === 'board' && x.id === s.host.id));
    const h = held([...tooClose(slabs)].sort());
    for (const e of drawn) hold(h, e.thread.id, e.a, e.b, e.p, e.q, e.over, slabs, others(e.a), others(e.b));
    property.constructions[c.id] = h;
  }
  const outBoards: Record<string, unknown> = {};
  for (const b of list) {
    const own = twoSided(b) ? slabsOf([[b.id, {a: [-b.w / 2, -CARDBOARD / 2], b: [b.w / 2, -CARDBOARD / 2], n: [0, 1], bottom: -b.h / 2, top: b.h / 2}]]) : [];
    const h = held();
    const rows = drawnThreads(doc, b.id).map(e => {
      const p = pinOf(e.a, designs.get(e.a.design)), q = pinOf(e.b, designs.get(e.b.design)), over = overBoard(p, q, b);
      if (own.length) hold(h, e.thread.id, e.a, e.b, p, q, over, own, [], []);   // on one wall, in its frame: its own cardboard
      return row(e.thread, e.a, e.b, p, q, over);
    });
    if (rows.length) { outBoards[b.id] = rows; nBoard += rows.length; }
    if (h.threads) property.boards[b.id] = h;
  }
  const point = (c: Construction | undefined, v: At, name: string): Vec3 => {
    if (Array.isArray(v)) return v;
    const w = c?.walls.find(x => x.board === v.board), t = w ? c?.tables.find(x => x.id === w.table) : undefined, b = boards.get(v.board);
    if (!w || !t || !b) throw new Error(`case ${name} puts a point on a wall its construction does not have`);
    return wallPoint(t, w, b, v.at);
  };
  const oc = cases.over ?? {};
  const outCases = {walls: {} as Record<string, Vec3[]>, boards: {} as Record<string, Vec3[]>, pieces: {} as Record<string, unknown>};
  for (const e of oc.walls ?? []) {
    const c = byCons.get(e.construction ?? '');
    const lines = c ? wallLines(c, boards) : new Map<string, WallLine>();
    const ws = Array.isArray(e.walls) ? e.walls.flatMap(x => (typeof x === 'string' ? (lines.has(x) ? [lines.get(x)!] : []) : [x])) : [...lines.values()];
    outCases.walls[e.name] = overWalls(point(c, e.p, e.name), point(c, e.q, e.name), ws);
  }
  for (const e of oc.boards ?? []) outCases.boards[e.name] = overBoard(e.p, e.q, (typeof e.board === 'string' ? boards.get(e.board) : e.board) as Board);
  for (const e of oc.pieces ?? []) outCases.pieces[e.name] = threadPieces(e.p, e.q, e.over ?? []);
  const constants = {THREAD_OVER, THREAD_CLEAR, CARDBOARD, MITER_LIMIT, STROKE_STEP, STROKE_DOT, STROKE_LIFT, STROKE_POINTS, PEN_LIST, PENS, PEN_COLOURS, PEN_COLOUR_NAMES};
  // `property` is the contract's alone (the parity takes it out before it compares the port's answers with these)
  fs.writeFileSync(outPath, JSON.stringify({constants, constructions: outCons, boards: outBoards, cases: outCases, property}));
  const all = [...Object.values(property.constructions), ...Object.values(property.boards)];
  console.log(`stickers_cardboard_runner over: ${cons.constructions.length} constructions, ${nThreads} threads between walls (${nOver} over a wall), ${nBoard} threads on one board; ${Object.keys(outCases.walls).length} cases over walls, ${Object.keys(outCases.boards).length} over a board, ${Object.keys(outCases.pieces).length} pieces; the property: ${all.reduce((n, h) => n + h.through, 0)} threads through cardboard, ${all.reduce((n, h) => n + h.pressed, 0)} with a pressed pin, ${all.reduce((n, h) => n + h.close_through, 0)} through walls too close to another (the known limit)`);
}

const [mode, ...rest] = process.argv.slice(2);
if (mode === 'ops' && rest.length >= 4) ops(rest);
else if (mode === 'geometry' && rest.length >= 6) geometry(rest);
else if (mode === 'over' && rest.length >= 6) overMode(rest);
else {
  console.error('give: ops <base> <ops> <designs> <out> [<boards>|-] [<constructions>]  |  geometry|over <placements> <designs> <boards> <constructions> <cases|-> <out>');
  process.exit(2);
}
