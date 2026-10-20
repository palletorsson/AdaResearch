'use strict';

// Run from any directory:
// node doc/space/transformation-sampling-2026-09-17/check-browser-state.cjs
// This checks the page's actual JavaScript with a small DOM/Canvas stub.
// It does not substitute for browser rendering or Godot/headset verification.
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const crypto = require('node:crypto');

const repository = path.resolve(__dirname, '../../..');
const source = 'doc/research/possible-bodies/transformation-zoetrope.html';
const html = fs.readFileSync(path.join(repository, source), 'utf8');
const script = html.match(/<script>([\s\S]*?)<\/script>/);
if (!script) throw new Error(`No inline experiment script found in ${source}`);

let now = 0;
let nextFrame = null;
const context = new Proxy({}, {
  get: (object, key) => key in object ? object[key] : () => {},
  set: (object, key, value) => (object[key] = value, true),
});
const makeElement = () => ({
  value: '', checked: false, disabled: false, style: {}, events: {},
  addEventListener(name, callback) { this.events[name] = callback; },
  setAttribute() {},
  getContext() { return context; },
  getBoundingClientRect() { return { width: 590 }; },
});
const elements = {};
const environment = {
  console, Math, Number, RangeError, Object, Array, Map, Set,
  performance: { now: () => now },
  matchMedia: () => ({ matches: false }),
  devicePixelRatio: 1,
  requestAnimationFrame: callback => { nextFrame = callback; },
  ResizeObserver: class { observe() {} },
  document: {
    getElementById: id => elements[id] ??= makeElement(),
    createElement: () => makeElement(),
  },
  window: {},
};
vm.createContext(environment);
vm.runInContext(script[1], environment, { filename: source });
const api = environment.window.transformStudy;
const checks = [];
const check = (passed, name) => {
  checks.push({ name, passed: Boolean(passed) });
  console.log(`${passed ? 'PASS' : 'FAIL'} ${name}`);
};

let state = api.snapshot();
check(state.time === 0 && state.interval === 1 && state.sampleTime === 0,
  'Clock and sampling grid start at zero');

state = api.setTime(1.75);
check(state.paused && state.time === 1.75 && state.sampleTime === 1,
  'One-second sampling holds the previous pose');
check(Math.abs(state.studies.translation.sampled.offset[0] - 0.6) < 1e-12,
  'Translation reaches its 0.6-metre amplitude at one second');
check(Math.abs(state.studies.scale.sampled.scale - 1.3) < 1e-12,
  'Uniform scale reaches factor 1.3 at one second');
check(Math.abs(state.studies.rotation.sampled.angle - Math.PI / 2) < 1e-12,
  'Rotation reaches a quarter-turn at one second');

elements.interval.value = '4';
elements.interval.events.change();
state = api.snapshot();
check(state.time === 1.75 && state.sampleTime === 0,
  'Changing the interval resamples without resetting running time');
state = api.setTime(6.25);
check(state.sampleTime === 4,
  'Whole-cycle sampling remains anchored at time zero');
check(Math.abs(state.studies.combined.sampled.offset[0]) < 1e-12 &&
  Math.abs(state.studies.combined.sampled.scale - 1) < 1e-12,
  'Combined translation and scale return after a whole cycle');

elements.interval.value = '0.3333333333333333';
elements.interval.events.change();
state = api.setTime(1);
check(Math.abs(state.sampleTime - 1) < 1e-12,
  'Third-second sampling includes the exact one-second boundary');
state = api.setTime(1.2);
check(Math.abs(state.sampleTime - 1) < 1e-12,
  'Third-second sampling holds between sample boundaries');

now = 5000;
nextFrame(now);
check(api.snapshot().time === 1.2,
  'Paused time remains frozen when animation frames advance');
elements.marked.checked = true;
elements.marked.events.change();
check(api.snapshot().marked && api.snapshot().time === 1.2,
  'Adding a mark preserves running time');
elements.body.value = 'sphere';
elements.body.events.change();
check(api.snapshot().body === 'sphere', 'Sphere selection reaches the model');
elements.body.value = 'asymmetric';
elements.body.events.change();
check(api.snapshot().body === 'asymmetric', 'Unequal tetrahedron selection reaches the model');
elements.scrub.value = '2.125';
elements.scrub.events.input();
check(api.snapshot().time === 2.125, 'Paused scrubbing sets the requested time');
elements.pause.events.click();
now += 250;
nextFrame(now);
check(Math.abs(api.snapshot().time - 2.375) < 1e-12,
  'Resuming advances only the newly elapsed time');
check(api.snapshot().history.times.length === 12,
  'One cycle contains twelve stored still poses');

const passed = checks.filter(result => result.passed).length;
const report = {
  source,
  source_sha256: crypto.createHash('sha256').update(html).digest('hex'),
  generated_at: new Date().toISOString(),
  runtime: process.version,
  method: 'Actual inline page script executed in Node with DOM/Canvas stubs and a controlled animation clock.',
  limitations: 'State/formula checks only. Canvas pixels, real browser layout, Godot rendering and headset experience are not tested by this harness.',
  total: checks.length,
  passed,
  failed: checks.length - passed,
  checks,
};
fs.writeFileSync(path.join(__dirname, 'browser-state-checks.json'), JSON.stringify(report, null, 2) + '\n');
fs.writeFileSync(path.join(__dirname, 'browser-state-checks.txt'), [
  `Source: ${source}`,
  `SHA-256: ${report.source_sha256}`,
  `Runtime: ${report.runtime}`,
  report.method,
  report.limitations,
  '',
  ...checks.map(result => `${result.passed ? 'PASS' : 'FAIL'} ${result.name}`),
  '',
  `${passed}/${checks.length} checks passed.`,
  '',
].join('\n'));
console.log(`${passed}/${checks.length} checks passed. Reports saved beside this harness.`);
process.exitCode = passed === checks.length ? 0 : 1;
