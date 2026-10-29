// Tape designs: does the page paint what the game paints? Every design in
// commons/artifacts/tape_roll/tapes.json is painted by the page's rule (ada_encyclopedia
// src/lib/tape-design.ts texel) and compared texel for texel with what tape_design.gd painted
// (ada_run/tape_design/texels_gd.json, written by
//   godot --headless --path . --xr-mode off --script res://commons/testing/probe_tape_designs.gd -- texels).
// A design must match to within 1 of 255 per channel (rounding at a half); a negative, each design with
// its ratio moved by 0.1, must not. Run from the repo root:
//   ../ada_encyclopedia/node_modules/.bin/tsx tools/tape_design_check.ts      exit code = failures
import {readFileSync} from 'fs';
import {texel, validDesign, TILE, type TapeDesign} from '../../ada_encyclopedia/src/lib/tape-design';

const tapes: Record<string, unknown> = JSON.parse(readFileSync('commons/artifacts/tape_roll/tapes.json', 'utf-8')).tapes;
const gd: Record<string, number[]> = JSON.parse(readFileSync('ada_run/tape_design/texels_gd.json', 'utf-8'));
const paint = (d: TapeDesign) => { const out: number[] = []; for (let y = 0; y < TILE.h; y++) for (let x = 0; x < TILE.w; x++) out.push(...texel(d, x, y)); return out; };
const worst = (p: number[], q: number[]) => p.reduce((m, v, i) => Math.max(m, Math.abs(v - q[i])), 0);
let failed = 0;
for (const [id, raw] of Object.entries(tapes)) {
  const {design, error} = validDesign(raw);
  if (!design) { failed++; console.log(`FAIL ${id}: not a valid design (${error})`); continue; }
  if (!gd[id]) { failed++; console.log(`FAIL ${id}: Godot painted nothing for it`); continue; }
  const ts = paint(design), w = worst(ts, gd[id]);
  const moved = paint({...design, ratio: Math.min(1, design.ratio + 0.1)}), neg = worst(moved, gd[id]);
  const ok = w <= 1 && (design.pattern === 'solid' || neg > 1); if (!ok) failed++;
  console.log(`${ok ? 'ok  ' : 'FAIL'} ${id.padEnd(14)} ${design.pattern.padEnd(9)} ${TILE.w}x${TILE.h} texels: worst ${w}/255 apart${design.pattern === 'solid' ? '' : `; ratio +0.1 moves it ${neg}/255 (the check can fail)`}`);
}
console.log(`${failed} failed`);
process.exit(failed);
