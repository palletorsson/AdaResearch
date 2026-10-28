// Which knobs of the forces studies (and the twenty clocks they lead to) are really one knob? The spatial lab's forces studies
// (ada_encyclopedia/src/lib/colour-study.ts) are compiled in pairs and the two pictures compared
// number by number. A pair claimed SAME must compile to the identical expression (to 2e-4); a pair
// claimed DIFFERS must not, so every invariance has a negative beside it that proves the check can
// fail. Three cross-study claims read the same moving part out of two studies frame by frame.
// The address rules' "same picture as" partition, applied to physics: settings that make the same
// picture share their dimensionless groups, and the knobs that do not move them are scale.
// Run from the repo root:  ../ada_encyclopedia/node_modules/.bin/tsx tools/forces_same_picture.ts
// Exit code = failed claims.
import {STUDIES} from '../../ada_encyclopedia/src/lib/colour-study';

type V = Record<string, string | number>;
type Ex = {op?: string; parts?: Ex[]; of?: Ex; at?: number[]; id?: string; color?: string; [k: string]: unknown};
const study = (id: string) => { const s = STUDIES.find(x => x.id === id); if (!s) throw Error('no study ' + id); return s; };
const compile = (id: string, v: V) => study(id).compile(v);
const partsOf = (e: Ex): Ex[] => e.parts ?? (e.of ? partsOf(e.of) : []);

function diff(a: unknown, b: unknown, path = ''): string | null {
  if (typeof a === 'number' && typeof b === 'number') return Math.abs(a - b) <= 2e-4 ? null : `${path}: ${a} vs ${b}`;
  if (Array.isArray(a) && Array.isArray(b)) {
    if (a.length !== b.length) return `${path}: ${a.length} parts vs ${b.length}`;
    for (let i = 0; i < a.length; i++) { const d = diff(a[i], b[i], `${path}[${i}]`); if (d) return d; }
    return null;
  }
  if (a && b && typeof a === 'object' && typeof b === 'object') {
    const keys = new Set([...Object.keys(a), ...Object.keys(b)]);
    for (const k of keys) { const d = diff((a as Record<string, unknown>)[k], (b as Record<string, unknown>)[k], `${path}.${k}`); if (d) return d; }
    return null;
  }
  return a === b ? null : `${path}: ${String(a)} vs ${String(b)}`;
}
const without = (e: Ex, colours: string[]): Ex[] => partsOf(e).filter(p => !colours.includes(String((p.of as Ex | undefined)?.color ?? '')));

type Claim = {study: string; a: V; b: V; expect: 'same' | 'differs'; says: string; skip?: string[]};
const pad = {foresight: 'parabola'} as V, padHalf = {...pad, up: 3.5, forward: 3, draw_g: 2.45, fall_g: 2.45, walk: 0.7, hz: 30} as V;
const PAD_ARROWS = ['57f0ff', '84f4ff', 'f27340'];
const claims: Claim[] = [
  {study: 'launch_arc', a: {}, b: {v0: 5.68, g: 12}, expect: 'differs', says: 'the throw, as drawn: its arrow is 0.62 m per m/s, so a faster throw draws a longer arrow over the same arc'},
  {study: 'launch_arc', a: {}, b: {v0: 5.68, g: 12, vis: 0.31}, expect: 'same', says: 'the throw: only v0²/g sets its size (double the speed, quadruple g, halve the arrow’s m per m/s)'},
  {study: 'launch_arc', a: {}, b: {v0: 5.68}, expect: 'differs', says: '  negative: double the speed alone'},
  {study: 'launch_arc', a: {beat: 10}, b: {v0: 5.68, g: 12, vis: 0.31, beat: 5}, expect: 'same', says: 'the throw in time: the clock runs at v0/g, so the ball is where it was in half the time'},
  {study: 'launch_arc', a: {drag: 0.6}, b: {v0: 5.68, g: 12, vis: 0.31, drag: 1.2}, expect: 'same', says: 'the throw in air: v0²/g and b·v0/g (double the drag too)'},
  {study: 'launch_arc', a: {drag: 0.6}, b: {v0: 5.68, g: 12, vis: 0.31, drag: 0.6}, expect: 'differs', says: '  negative: the same air at the faster throw'},
  {study: 'spring_tower', a: {beat: 7}, b: {k: 11.2, m: 3, beat: 7}, expect: 'same', says: 'the spring: only k/m sets the swing (halve both)'},
  {study: 'spring_tower', a: {beat: 7}, b: {k: 11.2, beat: 7}, expect: 'differs', says: '  negative: halve k alone'},
  {study: 'spring_tower', a: {beat: 7, arrows: 'to scale'}, b: {k: 11.2, m: 3, beat: 7, arrows: 'to scale'}, expect: 'differs', says: 'the spring to scale: the same swing carries half the force'},
  {study: 'spring_tower', a: {beat: 30, damping: 6}, b: {k: 11.2, m: 3, damping: 3, beat: 30}, expect: 'same', says: 'the damped spring: k/m and ζ = c/2√(km) (halve c too)'},
  {study: 'spring_tower', a: {beat: 30, damping: 6}, b: {k: 11.2, m: 3, damping: 6, beat: 30}, expect: 'differs', says: '  negative: the same c on the lighter spring'},
  {study: 'force_pad', a: pad, b: padHalf, expect: 'same', skip: PAD_ARROWS, says: 'the pad and the body: halve every speed, quarter g, and halve the clock’s rate (arrows aside)'},
  {study: 'force_pad', a: pad, b: {...padHalf, hz: 60}, expect: 'differs', skip: PAD_ARROWS, says: '  negative: keep 60 Hz, and the stepping no longer scales'},
  {study: 'force_pad', a: pad, b: padHalf, expect: 'differs', says: 'the pad’s arrows: clamped to 0.6..1.6 m, so its drawing does not scale with the throw'},
  {study: 'phase_rods', a: {beat: 7}, b: {beat: 67}, expect: 'same', says: 'twenty clocks: the picture returns every period (6 s)'},
  {study: 'phase_rods', a: {beat: 7}, b: {beat: 37}, expect: 'differs', says: '  negative: half a period later'},
  {study: 'phase_rods', a: {beat: 7}, b: {mode: 'WAVE', step: 360, beat: 7}, expect: 'same', says: 'a phase step of 360° is no wave: the same picture as TOGETHER'},
  {study: 'phase_rods', a: {mode: 'DRIFT', beat: 1500}, b: {beat: 1500}, expect: 'same', says: 'the drift: 4 % fast gains a whole turn in period/0.04 = 150 s, and the grid is together again'},
  {study: 'phase_rods', a: {mode: 'DRIFT', beat: 750}, b: {beat: 750}, expect: 'differs', says: '  negative: at 75 s the back rows are half a turn ahead'},
  {study: 'centrifuge_ring', a: {beat: 9}, b: {v: 3.17, radius: 1.7, beat: 18, vel_scale: 0.36, pull_scale: 0.2}, expect: 'differs', says: 'the ring: the turn depends on v/r, its size on r: half the ring is a different picture (the pod and the track height do not scale)'},
];

let failed = 0;
console.log('SAME PICTURE AS: which knobs are one knob\n');
for (const c of claims) {
  const A = compile(c.study, c.a).expr as Ex, B = compile(c.study, c.b).expr as Ex;
  const d = c.skip ? diff(without(A, c.skip), without(B, c.skip)) : diff(A, B);
  const got = d === null ? 'same' : 'differs', ok = got === c.expect;
  if (!ok) failed++;
  console.log(`${ok ? 'ok  ' : 'FAIL'} ${c.study.padEnd(16)} ${got.padEnd(8)} ${c.says}${!ok || (got === 'differs' && process.argv.includes('--why')) ? `\n       first difference ${d ?? '(none)'}` : ''}`);
}

// cross-study: one moving part read out of two studies, frame by frame
const at = (id: string, v: V, part: string): number[] => { const p = partsOf(compile(id, v).expr as Ex).find(x => x.id === part); if (!p?.at) throw Error(`${id} has no ${part}`); return p.at; };
function track(label: string, f: (beat: number) => [number, number]) {
  let worst = 0;
  for (let b = 0; b <= 60; b++) { const [x, y] = f(b); worst = Math.max(worst, Math.abs(x - y)); }
  const ok = worst <= 3e-4; if (!ok) failed++;
  console.log(`${ok ? 'ok  ' : 'FAIL'} ${'across'.padEnd(16)} ${(ok ? 'same' : 'differs').padEnd(8)} ${label} (61 frames, worst ${worst.toExponential(1)} m)`);
}
console.log('');
// the spring is the ring's shadow: k/m = 4 and v/r = 2 give one omega; the spring's mass and the ring's pod.
// The two studies keep different clocks (the spring 0.1 s a beat, the ring 0.05 s), so spring beat b is ring beat 2b.
track('the spring is the ring’s shadow: √(k/m) = v/r = 2, amplitude = radius = 0.7', b => {
  const s0 = at('spring_tower', {k: 24, m: 6, amplitude: 0.7, beat: 0}, 'Mass')[1], r0 = at('centrifuge_ring', {v: 1.4, radius: 0.7, beat: 0}, 'Pod')[0];
  return [at('spring_tower', {k: 24, m: 6, amplitude: 0.7, beat: b}, 'Mass')[1] - s0, -(at('centrifuge_ring', {v: 1.4, radius: 0.7, beat: 2 * b}, 'Pod')[0] - r0)];
});
track('the spring’s swing does not know g: Moon and Earth, measured from where each hangs', b => {
  const e0 = at('spring_tower', {beat: 0}, 'Mass')[1], m0 = at('spring_tower', {g: 1.6, beat: 0}, 'Mass')[1];
  return [at('spring_tower', {beat: b}, 'Mass')[1] - e0, at('spring_tower', {g: 1.6, beat: b}, 'Mass')[1] - m0];
});
track('a rod’s eye is the spring again: period 2 s against √(k/m) = π, eye 0.58 out against amplitude 0.58', b => {
  const s0 = at('spring_tower', {k: Math.PI ** 2, m: 1, amplitude: 0.58, beat: 0}, 'Mass')[1], e0 = at('phase_rods', {period: 2, beat: 0}, 'Eye01')[1];
  return [at('spring_tower', {k: Math.PI ** 2, m: 1, amplitude: 0.58, beat: b}, 'Mass')[1] - s0, -(at('phase_rods', {period: 2, beat: b}, 'Eye01')[1] - e0)];
});
// a shadow at a different speed must not match: the negative for the shadow
let negWorst = 0;
for (let b = 0; b <= 60; b++) {
  const s = at('spring_tower', {k: 24, m: 6, amplitude: 0.7, beat: b}, 'Mass')[1] - at('spring_tower', {k: 24, m: 6, amplitude: 0.7, beat: 0}, 'Mass')[1];
  const r = -(at('centrifuge_ring', {v: 1.5, radius: 0.7, beat: 2 * b}, 'Pod')[0] - at('centrifuge_ring', {v: 1.5, radius: 0.7, beat: 0}, 'Pod')[0]);
  negWorst = Math.max(negWorst, Math.abs(s - r));
}
const negOk = negWorst > 0.05; if (!negOk) failed++;
console.log(`${negOk ? 'ok  ' : 'FAIL'} ${'across'.padEnd(16)} ${'differs'.padEnd(8)}   negative: the ring at v 1.5 (v/r = 2.14) drifts off the spring by ${negWorst.toFixed(3)} m`);

// every twin the studies offer, at a handful of settings each: the study's own "same picture as", held to it
console.log('\nTWINS: what each study vouches for, checked');
const SAMPLES: Record<string, V[]> = {
  spring_tower: [{}, {damping: 6, beat: 30}, {arrows: 'to scale', beat: 7}, {k: 40, m: 20, beat: 3}],
  force_pad: [{foresight: 'parabola'}, {approach: 'from the side', foresight: 'landing', beat: 20}, {up: 12, forward: 12, cap: '14 m/s (the court)', beat: 10}],
  launch_arc: [{}, {drag: 0.6, beat: 10}, {lands: 'on, 1 m below the pad', comparison: 'envelope', theta: 40}, {comparison: 'fan', v0: 5}],
  centrifuge_ring: [{}, {show: 'all of it', beat: 10}, {release: 20, beat: 32}],
  phase_rods: [{}, {mode: 'WAVE', beat: 5}, {mode: 'DRIFT', beat: 100}, {mode: 'DRIFT', beat: 1550}],
  shadow_chain: [{}, {beat: 17}, {reach: 0.9, period: 3}],
};
type T = {label: string; says: string; study: string; values: V; skip?: string[]; track?: {part: string; self: string; axis: number; sign: number; beats: number}};
let twins = 0;
for (const [id, samples] of Object.entries(SAMPLES)) for (const v of samples) {
  for (const tw of ((compile(id, v) as {twins?: T[]}).twins ?? [])) {
    twins++;
    let ok: boolean, how: string;
    if (tw.track) {
      const tr = tw.track, b0 = Number(v.beat ?? 0), t0 = Number(tw.values.beat ?? 0);
      const self0 = at(id, {...v, beat: b0}, tr.self)[1], other0 = at(tw.study, {...tw.values, beat: t0}, tr.part)[tr.axis];
      let worst = 0;
      for (let b = 0; b <= 60; b++) worst = Math.max(worst, Math.abs(tr.sign * (at(tw.study, {...tw.values, beat: t0 + b * tr.beats}, tr.part)[tr.axis] - other0) - (at(id, {...v, beat: b0 + b}, tr.self)[1] - self0)));
      ok = worst <= 3e-4; how = `moves as its ${tr.self} over 61 frames, worst ${worst.toExponential(1)} m`;
    } else {
      const A = compile(id, v).expr as Ex, B = compile(tw.study, tw.values).expr as Ex;
      const d = tw.skip ? diff(without(A, tw.skip), without(B, tw.skip)) : diff(A, B);
      ok = d === null; how = ok ? `the same picture${tw.skip ? ' (its named arrows aside)' : ''}` : `differs at ${d}`;
    }
    if (!ok) failed++;
    console.log(`${ok ? 'ok  ' : 'FAIL'} ${id.padEnd(16)} ${JSON.stringify(v).slice(0, 44).padEnd(45)} ${tw.label}${tw.study === id ? '' : ' (' + tw.study + ')'}: ${how}`);
  }
}
// inside the shadow: the three heights on one line, and a detuned spring off it
for (const [detune, expect] of [[0, 'one line'], [10, 'off the line']] as const) {
  let worst = 0;
  for (let b = 0; b <= 120; b++) { const v = {detune, beat: b * 3}, y = at('shadow_chain', v, 'Pod')[1]; worst = Math.max(worst, Math.abs(at('shadow_chain', v, 'Mass')[1] - y), Math.abs(at('shadow_chain', v, 'Eye')[1] - y)); }
  const ok = expect === 'one line' ? worst <= 2e-4 : worst > 0.05; if (!ok) failed++;
  console.log(`${ok ? 'ok  ' : 'FAIL'} ${'shadow_chain'.padEnd(16)} ${('detune ' + detune).padEnd(45)} ${expect}: wheel, mass and eye ${worst.toExponential(1)} m apart at worst over 36 s`);
}
console.log(`${twins} twins checked`);
console.log(`\n${failed} failed`);
process.exit(failed);
