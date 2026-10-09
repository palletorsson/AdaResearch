// Remote inspection of recorded Godot states and actual desktop walk traces.
// This is a section/plan diagram, not a second physics engine.
(async function () {
  const data = await (await fetch('ca-forms-data.json')).json();
  const el = id => document.getElementById(id);
  let mode = 1, reserved = false, generation = 14;
  const titles = ['Straight history', 'Sine bend', 'Sine breath', 'Sine in the rule'];
  const suffix = () => String(mode) + (mode === 3 && reserved ? '-reserved' : '');
  function warp(x, y, z) {
    const s = Math.sin(2 * Math.PI * z / 14);
    return [mode === 1 ? x + 1.4 * s : mode === 2 ? x * (1 + .5 * s) : x,
      mode === 2 ? y * (1 + .25 * s) : y];
  }
  function prepare(id) {
    const c = el(id), p = c.getContext('2d');
    p.fillStyle = '#10292f'; p.fillRect(0, 0, c.width, c.height);
    p.font = '16px system-ui'; p.lineWidth = 1;
    return p;
  }
  function drawSection(record) {
    const p = prepare('section-view'), z = (generation + .5) * .5;
    const point = (x, y) => { const v = warp(x, y, z); return [350 + v[0] * 40, 328 - v[1] * 40]; };
    for (let y = 0; y < 15; y++) for (let x = 0; x < 25; x++) {
      const a = point((x - 12.5) * .4, (y - 1) * .4), b = point((x - 11.5) * .4, y * .4);
      p.fillStyle = record.history[generation][y * 25 + x] ? '#b6c4bb' : '#1d3940';
      p.fillRect(a[0], b[1], b[0] - a[0] - .6, a[1] - b[1] - .6);
    }
    if (reserved) {
      const a = point(-1, 0), b = point(1, 2.4);
      p.strokeStyle = '#ffcc70'; p.setLineDash([5, 4]);
      p.strokeRect(a[0], b[1], b[0] - a[0], a[1] - b[1]); p.setLineDash([]);
    }
    // Fixed-size visitor, never stretched with the architecture.
    const c = point(0, 0); p.strokeStyle = '#ef9dba'; p.lineWidth = 2;
    p.strokeRect(c[0] - 12, c[1] - 72, 24, 72);
    p.fillStyle = '#ef9dba'; p.fillText('1.8 m visitor / 0.6 m wide', 20, 26);
    p.fillStyle = '#bcd1cb'; p.fillText('X / sites →', 560, 365);
    p.fillText('Y / sites ↑', 20, 365);
  }
  function drawPlan(record) {
    const p = prepare('plan-view'), at = (x, z) => [350 + x * 37, 420 - z * 25];
    // Solid material intersecting a 1.6 m-high horizontal slice.
    for (let g = 0; g < 28; g++) for (let x = 0; x < 25; x++) {
      const z = (g + .5) * .5;
      const hits = record.history[g].some((v, i) => v && i % 25 === x &&
        warp(0, (Math.floor(i / 25) - 1) * .4, z)[1] <= 1.6 &&
        warp(0, Math.floor(i / 25) * .4, z)[1] > 1.6);
      if (!hits) continue;
      p.fillStyle = '#93aaa7'; p.beginPath();
      [[x, g], [x + 1, g], [x + 1, g + 1], [x, g + 1]].forEach(([xx, gg], n) => {
        const a = at(warp((xx - 12.5) * .4, 0, gg * .5)[0], gg * .5);
        if (!n) p.moveTo(...a); else p.lineTo(...a);
      }); p.closePath(); p.fill();
    }
    p.strokeStyle = '#ef9dba'; p.lineWidth = 3; p.beginPath();
    record.report.walk.trace.forEach((v, i) => {const a = at(v[0], v[2]); if (i) p.lineTo(...a); else p.moveTo(...a);}); p.stroke();
    const end = record.report.walk.trace.at(-1), endpoint = at(end[0], end[2]);
    p.fillStyle = '#ef9dba'; p.beginPath(); p.arc(...endpoint, 5, 0, Math.PI * 2); p.fill();
    p.strokeStyle = '#ffcc70'; p.lineWidth = 1; p.setLineDash([6, 5]); p.beginPath();
    p.moveTo(35, at(0, (generation + .5) * .5)[1]); p.lineTo(665, at(0, (generation + .5) * .5)[1]); p.stroke(); p.setLineDash([]);
    p.fillStyle = '#bcd1cb'; p.fillText('Entrance / G0', 24, 450); p.fillText('Exit / 14 m', 24, 48);
    p.fillStyle = '#ef9dba'; p.fillText('Recorded desktop walk', 440, 450);
  }
  function render() {
    const record = data[suffix()], r = record.report;
    el('reserve').disabled = mode !== 3;
    el('reserve').checked = reserved;
    document.querySelectorAll('[data-mode]').forEach(b => b.setAttribute('aria-pressed', +b.dataset.mode === mode));
    el('strategy-title').textContent = titles[mode] + (reserved ? ' · reserved corridor' : '');
    el('form-photo').src = `ca-forms-form-${suffix()}.png`;
    el('inside-photo').src = `ca-forms-inside-${suffix()}.png`;
    el('form-photo').alt = `Actual Godot workshop: ${titles[mode]} outside`;
    el('inside-photo').alt = `Actual Godot workshop: ${titles[mode]} from inside`;
    el('totals').textContent = `${r.occupied.toLocaleString('en-US')} occupied cells across 28 generations · ${r.forced_empty} births or survivals suppressed`;
    el('walk-result').textContent = r.walk.passed ? 'Desktop walk: crossed the full 14 m vault.' : `Desktop walk: stopped at z = ${r.walk.finish_z.toFixed(2)} m. No complete passage in this test.`;
    el('generation-reading').textContent = `Generation ${generation} / 27 · z = ${(generation * .5).toFixed(1)}–${((generation + 1) * .5).toFixed(1)} m`;
    el('section-reading').textContent = `This section: ${record.history[generation].reduce((s, v) => s + v, 0)} occupied sites. ${generation === 0 ? 'Authored seed; no update yet.' : `${r.changed[generation]} sites changed since the previous generation. Birth threshold: ${r.thresholds[generation]} of 8 neighbours; survival threshold: 4.`}`;
    el('strategy-note').textContent = mode < 3 ? 'Every saved cell agrees with the straight version. The transformation changes coordinates; the visitor keeps the same size.' : reserved ? 'The rule tries to occupy the protected strip. We reject 160 decisions across the recorded run. Later differences propagate beyond those rejections.' : 'Sine changes the birth threshold between 2 and 6. The same initial arch develops into an obstruction.';
    drawSection(record); drawPlan(record);
  }
  document.querySelectorAll('[data-mode]').forEach(b => b.addEventListener('click', () => {mode = +b.dataset.mode; reserved = false; render();}));
  el('reserve').addEventListener('change', e => {reserved = e.target.checked; render();});
  el('generation').addEventListener('input', e => {generation = +e.target.value; render();});
  el('previous-generation').addEventListener('click', () => {generation = Math.max(0, generation - 1); el('generation').value = generation; render();});
  el('next-generation').addEventListener('click', () => {generation = Math.min(27, generation + 1); el('generation').value = generation; render();});
  render();
})().catch(error => {document.getElementById('totals').textContent = `Could not load the recorded comparison: ${error.message}`;});
