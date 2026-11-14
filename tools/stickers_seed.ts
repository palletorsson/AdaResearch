// Stickers: write the starter set into the truth, and keep it derived. The starter designs are built by the
// encyclopedia's rules (ada_encyclopedia src/lib/sticker-starter.ts, stickers.ts) from the project's own words - the
// transition cards are read from commons/modular/terms.json here, never retyped - and merged into
// commons/data/stickers/designs.json: designs made by hand (by anything but 'starter') are kept as they are, starter
// designs are replaced. boards.json gets the visitors' board if it has none; placements.json is created empty (with
// --demo, a few stickers on the visitors' board and the bench so every medium shows one at once). Run from the repo
// root:
//   ../ada_encyclopedia/node_modules/.bin/tsx tools/stickers_seed.ts [--demo] [--research-board] [--check]
// The RESEARCH stickers (one per spine sequence) are derived from commons/maps/curriculum_spine.json (order, phase,
// phase colour, role) and commons/maps/sequences/<id>.json (title, truth). --research-board adds the board 'research'
// and lays them out on it in spine order, once (a sticker already there, or peeled from there, is not laid again).
// --check writes nothing and exits 1 when designs.json is not what the rules derive (a starter design edited by
// hand, or rules changed without a re-seed).
import {readFileSync, writeFileSync, mkdirSync, existsSync, renameSync} from 'fs';
import {readingDesigns, starterDesigns, type CardTerm, type Reading, type ResearchTerm} from '../../ada_encyclopedia/src/lib/sticker-starter';
import {
  BENCH, boardsText, cleanBoardsDoc, cleanDesignsDoc, cleanPlacementsDoc, DEFAULT_BOARD, designsText, emptyBoards,
  emptyPlacements, placementsText, upForTurn, type Placed, type DesignsDoc,
} from '../../ada_encyclopedia/src/lib/stickers';

const DIR = 'commons/data/stickers';
const args = new Set(process.argv.slice(2));
const now = new Date().toISOString().replace(/\.\d+Z$/, 'Z');

const terms = JSON.parse(readFileSync('commons/modular/terms.json', 'utf-8')).terms as Record<string, {card?: {formula?: string; motive?: string; op?: string; said?: string}}>;
const cards: CardTerm[] = Object.entries(terms)
  .filter(([, v]) => v && v.card && typeof v.card.formula === 'string')
  .map(([key, v]) => ({key, formula: v.card!.formula!, motive: v.card!.motive ?? '', op: v.card!.op ?? '', said: v.card!.said}));
const spine = JSON.parse(readFileSync('commons/maps/curriculum_spine.json', 'utf-8'));
const phases = spine.phases as Record<string, {name: string; color: string}>;
const research: ResearchTerm[] = [];
for (const s of spine.spine.sequences as {name: string; phase: string; order: number; qfep_role?: string}[]) {
  const file = `commons/maps/sequences/${s.name}.json`;
  if (!existsSync(file)) continue;
  const seqs = JSON.parse(readFileSync(file, 'utf-8')).sequences as Record<string, {name?: string; truth?: string; description?: string}>;
  const e = seqs[s.name] ?? Object.values(seqs)[0];
  if (!e?.name) continue;
  const truth = (e.truth || (e.description ?? '').split(/(?<=\.)\s/)[0] || '').trim();
  const ph = phases[s.phase] ?? {name: s.phase, color: '#4a90d9'};
  research.push({key: s.name, order: s.order, phase: s.phase, phaseName: ph.name, phaseColor: ph.color.toLowerCase(), title: e.name, truth, role: s.qfep_role ?? ''});
}

// THE READINGS (paradoxes and punctums) are authored in commons/data/stickers/readings.json, each with the VERBATIM
// passage of the text it reads, so that a reading follows its text as the hall text follows the map. The seed stops
// (exit 1, before it writes anything) and names the reading when:
//   - its file is gone, or its quote is no longer there: the quote's pieces ('...' or the ellipsis between them) must
//     be found IN ORDER, each inside ONE block of the text (a paragraph or a heading; HTML comments are not text),
//     each at least three words, with whitespace, emphasis marks and curly quotes evened out (an underscore only at a
//     word's edge, so a snake_case name keeps its own);
//   - its lettering says more than its quote: every piece of a and b (split the same way) must be in the quote;
//   - it is not a paradox with both halves or a punctum, its sequence is neither a spine sequence nor 'framework', or
//     it cannot be drawn (a character the sticker alphabet lacks).
// The authored line number is a reader's hint only (the design names the file, not the line, so an edit above the
// passage does not churn the stickers). The colour is the phase colour of the reading's sequence (synthesis for the
// framework). --readings=<file> reads another readings file and writes NOTHING (a test; it implies --check).
const readingsArg = process.argv.slice(2).find(a => a.startsWith('--readings='))?.slice('--readings='.length);
if (readingsArg !== undefined) {
  args.add('--check');
  if (!readingsArg || !existsSync(readingsArg)) { console.log(`--readings: '${readingsArg}' does not exist`); process.exit(1); }
}
const READINGS = readingsArg || `${DIR}/readings.json`;
const spineOrder = new Map((spine.spine.sequences as {name: string; phase: string; order: number}[]).map(s => [s.name, s]));
const even = (s: string) => s.replace(/[‘’]/g, "'").replace(/[“”]/g, '"').replace(/[*`]/g, '')
  .replace(/(^|[^\w])_+|_+(?=[^\w]|$)/g, '$1').replace(/\s+/g, ' ').trim();
const blocksOf = (body: string): string[] => {
  const out: string[] = [];
  for (const chunk of body.replace(/<!--[\s\S]*?-->/g, '\n\n').split(/\r?\n[ \t]*\r?\n/)) {
    let para: string[] = [];
    for (const line of chunk.split(/\r?\n/)) {
      if (/^\s*#/.test(line)) { if (para.length) out.push(para.join(' ')); para = []; out.push(line.replace(/^\s*#+\s*/, '')); }
      else para.push(line);
    }
    if (para.length) out.push(para.join(' '));
  }
  return out.map(even).filter(Boolean);
};
const piecesOf = (q: string) => q.split(/\s*(?:\.\.\.|…)\s*/).map(even).filter(Boolean);
const wordCount = (p: string) => p.split(' ').filter(w => /[A-Za-z0-9]/.test(w)).length;
// the first piece not found when the pieces are looked for in order, each inside one block (null: all found)
const missingInOrder = (blocks: string[], pieces: string[]): string | null => {
  let b = 0, at = 0;
  for (const p of pieces) {
    let found = false;
    for (; b < blocks.length; b++, at = 0) {
      const i = blocks[b].indexOf(p, at);
      if (i >= 0) { at = i + p.length; found = true; break; }
    }
    if (!found) return p;
  }
  return null;
};
const readings: Reading[] = [];
const unread: string[] = [];
if (existsSync(READINGS)) {
  for (const r of (JSON.parse(readFileSync(READINGS, 'utf-8')) as {readings: Reading[]}).readings) {
    const where = `${r.id}:`;
    if (r.kind !== 'paradox' && r.kind !== 'punctum') { unread.push(`${where} kind must be 'paradox' or 'punctum'`); continue; }
    if (!r.a || (r.kind === 'paradox' && !r.b)) { unread.push(`${where} a ${r.kind} needs ${r.kind === 'paradox' ? 'a and b' : 'a'}`); continue; }
    if (!spineOrder.has(r.sequence) && r.sequence !== 'framework') { unread.push(`${where} sequence '${r.sequence}' is not a spine sequence (or 'framework')`); continue; }
    if (!existsSync(r.file)) { unread.push(`${where} ${r.file} is gone`); continue; }
    const pieces = piecesOf(r.quote);
    const short = pieces.find(p => wordCount(p) < 3);
    if (!pieces.length || short !== undefined) { unread.push(`${where} every piece of the quote needs three words or more: "${short ?? ''}"`); continue; }
    const missing = missingInOrder(blocksOf(readFileSync(r.file, 'utf-8')), pieces);
    if (missing !== null) { unread.push(`${where} no longer in ${r.file} (in order, each inside one paragraph): "${missing.slice(0, 70)}"`); continue; }
    const said = even(r.quote).toLowerCase();
    const over = [r.a, r.b ?? ''].flatMap(piecesOf).find(p => !said.includes(p.toLowerCase()));
    if (over !== undefined) { unread.push(`${where} the lettering says more than its quote: "${over.slice(0, 70)}"`); continue; }
    // a reading of a spine sequence wears its phase's colour; one of the framework wears synthesis
    const seq = spineOrder.get(r.sequence);
    const phaseColor = (phases[seq ? seq.phase : 'synthesis']?.color ?? '').toLowerCase();
    readings.push({...r, color: r.color ?? (phaseColor || undefined)});
  }
}
const undrawn = readingDesigns(readings).skipped;
for (const s of undrawn) unread.push(`${s.key}: cannot be drawn - ${s.why}`);
if (unread.length) {
  console.log(`readings: ${unread.length} reading(s) refused - re-read them, re-letter them or retire them:\n  ${unread.join('\n  ')}`);
  process.exit(1);
}
const starter = starterDesigns(cards, research, readings);

const read = (name: string) => (existsSync(`${DIR}/${name}`) ? JSON.parse(readFileSync(`${DIR}/${name}`, 'utf-8')) : null);
const write = (name: string, text: string) => {
  mkdirSync(DIR, {recursive: true});
  const tmp = `${DIR}/${name}.${process.pid}.tmp`;
  writeFileSync(tmp, text);
  renameSync(tmp, `${DIR}/${name}`);
};

const oldRaw = read('designs.json');
const old: DesignsDoc = oldRaw ? (cleanDesignsDoc(oldRaw).doc ?? (() => { throw new Error('designs.json does not validate'); })()) : {version: 1, revision: 0, designs: [], sheets: []};
const starterIds = new Set(starter.designs.map(d => d.id));
const hand = old.designs.filter(d => d.by !== 'starter' && !starterIds.has(d.id));
// a starter design the rules no longer make (a retired reading, a card whose term went) is KEPT while any sticker still
// uses it - on or peeled, since a peel is an event and the record stays - marked by 'retired', so it is kept from then
// on as a hand-made one is: dropping it would leave stickers without a design and every later save refused
const usedIds = new Set(((read('placements.json')?.stickers ?? []) as {design?: string}[]).map(s => String(s.design ?? '')));
const retired = old.designs.filter(d => d.by === 'starter' && !starterIds.has(d.id) && usedIds.has(d.id)).map(d => ({...d, by: 'retired'}));
for (const d of retired) console.log(`  kept, retired: ${d.id} (still used by a sticker)`);
const merged: DesignsDoc = {
  version: 1,
  revision: old.revision,
  designs: [...starter.designs, ...hand, ...retired],
  sheets: [...starter.sheets, ...old.sheets.filter(s => !starter.sheets.some(t => t.id === s.id))],
};
const before = existsSync(`${DIR}/designs.json`) ? readFileSync(`${DIR}/designs.json`, 'utf-8') : '';   // the file's own text, not a re-derivation
const after = designsText({...merged, revision: old.revision});
console.log(`starter: ${starter.designs.length} designs (${starter.designs.filter(d => d.family === 'cards').length} cards), ${starter.sheets.length} sheets; kept by hand: ${hand.length}`);
for (const s of starter.skipped) console.log(`  skipped card ${s.key}: ${s.why}`);

if (args.has('--check')) {
  const same = before === after;
  console.log(same ? 'designs.json is what the rules derive' : 'designs.json differs from what the rules derive: run tools/stickers_seed.ts');
  process.exit(same ? 0 : 1);
}
if (before !== after) write('designs.json', designsText({...merged, revision: old.revision + 1}));
console.log(before === after ? 'designs.json unchanged' : `designs.json written (revision ${old.revision + 1})`);

const boards = read('boards.json');
if (!boards) {
  write('boards.json', boardsText({...emptyBoards(), revision: 1}));
  console.log('boards.json written (the visitors\' board)');
} else if (!cleanBoardsDoc(boards).doc) {
  throw new Error('boards.json does not validate');
}

const placed = read('placements.json');
if (!placed || (args.has('--demo') && (cleanPlacementsDoc(placed, now).doc?.stickers.length ?? 0) === 0)) {
  const doc = placed ? cleanPlacementsDoc(placed, now).doc! : emptyPlacements();
  if (args.has('--demo')) {
    const at = (x: number, y: number, z: number): [number, number, number] => [x, y, z];
    const demo: Placed[] = [
      {id: 'seed-board-triangle', design: 'here_pink_triangle', host: {kind: 'board', id: DEFAULT_BOARD.id}, at: at(-0.45, 0.12, 0), n: [0, 0, 1], up: upForTurn(0), size: 0.24, z: 1, by: 'starter', t: now, state: 'on', moves: 0},
      {id: 'seed-board-question', design: 'note_question', host: {kind: 'board', id: DEFAULT_BOARD.id}, at: at(0.25, 0.2, 0), n: [0, 0, 1], up: upForTurn(-4), size: 0.3, z: 2, by: 'starter', t: now, state: 'on', moves: 0},
      {id: 'seed-board-thicken', design: 'sieve_thicken', host: {kind: 'board', id: DEFAULT_BOARD.id}, at: at(0.4, -0.22, 0), n: [0, 0, 1], up: upForTurn(6), size: 0.22, z: 3, by: 'starter', t: now, state: 'on', moves: 0},
      {id: 'seed-sphere-here', design: 'here_you_are_here', host: {kind: 'primitive', id: 'sphere'}, at: at(0, 0, BENCH.items[1].r!), n: [0, 0, 1], up: [0, 1, 0], size: 0.18, z: 4, by: 'starter', t: now, state: 'on', moves: 0},
      {id: 'seed-box-minus', design: 'note_minus', host: {kind: 'primitive', id: 'box'}, at: at(0, 0.05, 0.25), n: [0, 0, 1], up: [0, 1, 0], size: 0.3, z: 5, by: 'starter', t: now, state: 'on', moves: 0},
      {id: 'seed-slab-dark', design: 'sieve_dark_spot', host: {kind: 'primitive', id: 'slab'}, at: at(0.1, 0, 0.02), n: [0, 0, 1], up: [0, 1, 0], size: 0.2, z: 6, by: 'starter', t: now, state: 'on', moves: 0},
    ];
    doc.stickers = demo;
    doc.revision += 1;
  }
  write('placements.json', placementsText(doc));
  console.log(`placements.json written (${doc.stickers.length} stickers)`);
}

// A board's 7 x 4 grid of slots. A new sticker goes in the FIRST FREE slot - a slot is taken by any sticker there, on
// or peeled (a peel leaves its record) - so a reading added later never lands on another; past the 28th slot the seed
// refuses and says so, rather than lay a sticker below the paper.
const SLOTS: [number, number][] = Array.from({length: 28}, (_, i) => [-0.96 + (i % 7) * 0.32, 0.47 - Math.floor(i / 7) * 0.31]);
function layOnGrid(pdoc: {stickers: Placed[]}, board: string, items: {id: string; design: string}[], tilt: (i: number) => number): number {
  const mine = () => pdoc.stickers.filter(s => s.host.kind === 'board' && s.host.id === board);
  let added = 0;
  items.forEach((it, i) => {
    if (pdoc.stickers.some(s => s.id === it.id)) return;
    const slot = SLOTS.find(([x, y]) => !mine().some(s => Math.hypot(s.at[0] - x, s.at[1] - y) < 0.06));
    if (!slot) { console.log(`  no free slot on '${board}' for ${it.id}: the board holds 28 (not laid)`); return; }
    pdoc.stickers.push({id: it.id, design: it.design, host: {kind: 'board', id: board}, at: [slot[0], slot[1], 0], n: [0, 0, 1],
      up: upForTurn(tilt(i)), size: 0.27, z: pdoc.stickers.length + 1, by: 'starter', t: now, state: 'on', moves: 0});
    added += 1;
  });
  return added;
}

// THE RESEARCH BOARD: every spine sequence's sticker, in spine order, seven to a row (laid once)
if (args.has('--research-board')) {
  const RESEARCH_BOARD = {id: 'research', title: 'The research, in stickers', w: 2.4, h: 1.36, paper: '#f4f0e6',
    note: 'One sticker per spine sequence of Ada Research, in spine order: its idea as a motif, its name, its question; the colour is its QFEP phase. Derived by tools/stickers_seed.ts from commons/maps/curriculum_spine.json and the sequence files.'};
  const bdoc = cleanBoardsDoc(read('boards.json') ?? emptyBoards()).doc!;
  if (!bdoc.boards.some(b => b.id === RESEARCH_BOARD.id)) {
    bdoc.boards.push(RESEARCH_BOARD);
    bdoc.revision += 1;
    write('boards.json', boardsText(bdoc));
    console.log(`boards.json: the board 'research' added (revision ${bdoc.revision})`);
  }
  const pdoc = cleanPlacementsDoc(read('placements.json') ?? emptyPlacements(), now).doc!;
  const ordered = starter.designs.filter(d => d.family === 'research');
  const added = layOnGrid(pdoc, RESEARCH_BOARD.id, ordered.map(d => ({id: `seed-research-${d.id.slice('research_'.length)}`.slice(0, 64).replace(/_/g, '-'), design: d.id})),
    i => ((i * 37) % 7) - 3);
  if (added) {
    pdoc.revision += 1;
    write('placements.json', placementsText(pdoc));
    console.log(`placements.json: ${added} research stickers laid on the board 'research' (revision ${pdoc.revision})`);
  }
}

// THE READINGS BOARD: the paradoxes and punctums in spine order (the framework's last), in the grid's free slots
if (args.has('--readings-board')) {
  const READINGS_BOARD = {id: 'readings', title: 'Paradoxes and punctums', w: 2.4, h: 1.36, paper: '#f4f0e6',
    note: 'What the texts hold true at once (paradoxes: the split badges) and the details in them that prick (punctums: the photograph prints), each with the line it reads. Chosen from 112 candidates read out of the hall texts and the framework; tools/stickers_seed.ts checks that every line is still in its text (commons/data/stickers/readings.json).'};
  const bdoc = cleanBoardsDoc(read('boards.json') ?? emptyBoards()).doc!;
  if (!bdoc.boards.some(b => b.id === READINGS_BOARD.id)) {
    bdoc.boards.push(READINGS_BOARD);
    bdoc.revision += 1;
    write('boards.json', boardsText(bdoc));
    console.log(`boards.json: the board 'readings' added (revision ${bdoc.revision})`);
  }
  const pdoc = cleanPlacementsDoc(read('placements.json') ?? emptyPlacements(), now).doc!;
  const rank = (r: Reading) => spineOrder.get(r.sequence)?.order ?? 99;
  const ordered = readings.slice().sort((p, q) => rank(p) - rank(q))
    .map(r => starter.designs.find(d => d.id === `${r.kind}_${r.id}`.slice(0, 41)))
    .filter((d): d is NonNullable<typeof d> => !!d);
  const added = layOnGrid(pdoc, READINGS_BOARD.id, ordered.map(d => ({id: `seed-reading-${d.id}`.slice(0, 64).replace(/_/g, '-'), design: d.id})),
    i => ((i * 29) % 9) - 4);
  if (added) {
    pdoc.revision += 1;
    write('placements.json', placementsText(pdoc));
    console.log(`placements.json: ${added} readings laid on the board 'readings' (revision ${pdoc.revision})`);
  }
}
