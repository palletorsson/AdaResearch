"""Publish B19's real Godot captures and bounded implementation evidence."""
from pathlib import Path
import hashlib
import html
import json
import shutil

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/plans/biome-ladder'
PUBLIC = ROOT.parent / 'ada_encyclopedia/public/biome-plan'
RUN = ROOT / 'ada_run/biome_ladder_arrays'


def publish():
    OUT.mkdir(parents=True, exist_ok=True)
    before = OUT / 'arrays-before.png'
    if not before.exists():
        shutil.copy2(ROOT / 'ada_run/biome_ladder_play/stage-2.png', before)
    files = ['arrays-before.png']
    for src, dst in [('array-ready.png', 'arrays-after.png'),
                     ('row-volley.png', 'arrays-volley.png'),
                     ('zigzag-paths.png', 'arrays-paths.png'),
                     ('array-vacancy.png', 'arrays-vacancy.png')]:
        shutil.copy2(RUN / src, OUT / dst)
        files.append(dst)
    checks = []
    for title, path, destination in [
        ('Array, addresses, volleys, paths and cover', 'biome_ladder_arrays/report.json', 'arrays-checks.json'),
        ('Five-stage behaviour', 'biome_ladder_play/report.json', 'arrays-stage-checks.json'),
        ('Desktop input and projectile physics', 'biome_ladder_play/desktop/report.json', 'arrays-desktop-checks.json'),
        ('Tiling and floor collision', 'biome_tiling_floor/report.json', 'arrays-tiling-checks.json'),
        ('Controlled XR input, skull hit and fall', 'biome_ladder_skull_hits/report.json', 'arrays-xr-checks.json'),
    ]:
        report = json.loads((ROOT / 'ada_run' / path).read_text())
        assert report['passed'] == report['total'], title
        shutil.copy2(ROOT / 'ada_run' / path, OUT / destination)
        checks.append((title, report['passed'], report['total'], destination))
        files.append(destination)
    sources = ['commons/hazards/biome_ladder/' + name for name in
               ['ladder_encounter.gd', 'ladder_skull.gd', 'ladder_ball.gd', 'array_path.gd']]
    sources += ['tools/probes/' + name for name in
                ['biome_ladder_arrays.gd', 'biome_ladder.gd', 'biome_tiling_floor.gd',
                 'desktop_biome_catalyst.gd', 'biome_ladder_skull_hits.gd']]
    evidence = {'iteration': 'B19', 'date': '2026-10-13',
                'sources': {path: hashlib.sha256((ROOT / path).read_bytes()).hexdigest() for path in sources},
                'checks': [{'name': t, 'passed': p, 'total': n, 'report': f} for t, p, n, f in checks],
                'limits': 'Controlled Godot runs, not a physical headset or frame-rate test. Existing cleanup warnings remain.'}
    (OUT / 'arrays-evidence.json').write_text(json.dumps(evidence, indent=2), encoding='utf-8')
    files.append('arrays-evidence.json')
    table = '\n'.join(f'| {t} | {p}/{n} | [{f}]({f}) |' for t, p, n, f in checks)
    report = f'''# B19 — a standing array

13 October 2026. Built from Palle's edited scaffold. Five playable stages remain; this upgrades Arrays and carries the behaviour into Colour and Tiling.

## What changed

- Nine skulls occupy a standing 3 × 3 grid. Labels are `[row, column]`, starting at zero. The wire frame shows each place without adding a wall.
- One catalyst hit drops the skull. Its address remains and reads EMPTY; neighbours keep their original addresses. RESET restores the nine occupants.
- START fires rows 0, 1, 2, then columns 0, 1, 2. One group is scheduled every 4.8 seconds; each head warns for 1.2 seconds. Empty places do not fire. REST stops warnings and clears shots.
- Each shot stores a list of positions. The warning draws that list; the projectile traverses the same list at 1.8 metres per second, sweeping each edge for collision. After the last point it continues along the final direction. The target is sampled when the warning begins; these are not homing shots.
- Transformation's small head motion, turning and bounded projectile growth remain. Heads hold still during the warning so the muzzle matches the announced path.
- Entrance refuge boxes move outward, becoming 3 metres high and 2 metres wide/deep. All nine heads are visible from the arrival view; test shots from all nine addresses stop at the left refuge.
- Tile shrinking and rotation remain. Colour adds colour; Tiling still repeats the catalyst impact across 18 matching tiles. Skull impacts paint only the actual receiving tile.

## Play

Game menu → Biome Ladder → **3 / ARRAY**. START or T begins volleys. Left click shoots; arrow keys move; R resets. In VR use the supplied hand form and trigger. The standalone scene is `res://commons/hazards/biome_ladder/ladder_world.tscn`.

Try removing the middle skull. Read the empty address while the next row passes through it. Then compare Colour and Tiling: the same array and paths remain while the floor acquires later operations.

## Evidence

| Check | Passed | Raw result |
|---|---|---|
{table}

All runs exited 0. The array probe includes normal scheduled volleys, actual projectile collisions, a falling vacancy, reset, corner traversal, inherited floor operations and refuge shots from all nine addresses. Desktop and controlled XR input use the actual catalyst projectile. Tiling's old hard-coded cover target was replaced with the actual box position; its floor-paint test now verifies the receiving collider explicitly.

The pictures are rendered by Godot in controlled probe scenes. Overview/volley shots temporarily hold head motion to make comparison readable; the game retains motion. They are not a manual headset playthrough. Physical headset comfort, difficulty and performance remain to be assessed. Existing ObjectDB cleanup warnings remain at shutdown. Claude's earlier Tiling console-reach finding is still open; this pass does not certify the complete route.

## Handoff

`array_path.gd` supplies the position list and line drawing; `ladder_ball.gd` follows it; `ladder_skull.gd` manages warnings; `ladder_encounter.gd` owns addresses and volley order. Source hashes are in [arrays-evidence.json](arrays-evidence.json). Claude-owned probes and review remain untouched. Tutorial/final.md and sequence order are unchanged. Preserve user edits in SCAFFOLD.json.
'''
    (OUT / 'ARRAYS.md').write_text(report, encoding='utf-8')
    files.append('ARRAYS.md')
    rows = ''.join(f'<tr><td>{html.escape(t)}</td><td><a href="{f}">{p}/{n}</a></td></tr>' for t, p, n, f in checks)
    page = '''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Biome · a standing array</title><style>
*{box-sizing:border-box}body{margin:0;background:#f5f3ed;color:#252821;font:17px/1.6 system-ui,sans-serif}main{max-width:1280px;margin:auto;padding:38px 5vw 80px}nav{display:flex;gap:22px;flex-wrap:wrap;font-size:14px}a{color:#315e47;text-underline-offset:4px}h1{font:clamp(40px,5vw,70px)/1.08 Georgia,serif;margin:26px 0 18px;max-width:850px}h2{font:30px/1.2 Georgia,serif;margin:42px 0 16px}.intro{max-width:850px;font-size:21px}small,figcaption{color:#596454;font-size:13px}figure{margin:26px 0}img{display:block;width:100%;height:auto;background:#252821}figcaption{margin-top:8px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:24px}.pair figure{margin:12px 0}.play{padding:20px 25px;border-left:3px solid #315e47;background:#e8ecdf;margin:28px 0}table{border-collapse:collapse;width:100%;max-width:850px}td,th{text-align:left;padding:10px;border-bottom:1px solid #cbd1c3}li{margin:8px 0}.limits{font-size:14px;max-width:850px}details{margin:28px 0}summary{cursor:pointer}@media(max-width:700px){.pair{grid-template-columns:1fr}main{padding:24px 20px 60px}}@media print{nav,.play{display:none}figure{break-inside:avoid}}
</style></head><body><main><nav><a href="scaffold.html#array_tutorial">Edit the change list</a><a href="index.html#stage-2">Biome ladder</a><a href="ARRAYS.md">Implementation report</a></nav><p><small>B19 · BUILT IN GODOT · 13 OCTOBER 2026</small></p><h1>Nine places.<br>One ordered volley.</h1><p class="intro">Arrays now makes the group visible. A row fires, then another; later a column answers. Remove a skull and its place remains.</p>
<figure><img src="arrays-after.png" alt="Actual Godot view of nine addressed skulls in an upright three by three grid above a black and white floor"><figcaption>AFTER · standing view inside the actual Arrays biome. Earlier cover, pickups and floor reactions remain.</figcaption></figure>
<div class="play"><b>Play: Game menu → Biome Ladder → 3 / ARRAY.</b><br>START or T begins the volleys. Left click shoots. Arrow keys move. R resets.<br>VR uses the supplied hand sphere and trigger; headset playtesting is still pending.</div>
<h2>The list becomes a path</h2><p>Rows 0, 1 and 2 fire, followed by columns 0, 1 and 2. Every 4.8 seconds one group is selected. The warning shows the stored positions; the slow ball follows that same zigzag. You can move after the target is chosen.</p>
<figure><img src="arrays-paths.png" alt="Oblique Godot view showing the zigzag projectile paths between the skull array and the visitor"><figcaption>Same position list used for the warning and the projectile. Oblique camera makes the bends visible.</figcaption></figure>
<div class="pair"><figure><img src="arrays-volley.png" alt="Three skulls firing as the middle row is selected"><figcaption>A row acts together. Next, a different group.</figcaption></figure><figure><img src="arrays-vacancy.png" alt="Middle skull has fallen and its original cell still reads row one column one EMPTY"><figcaption>A hit drops the occupant. The address stays.</figcaption></figure></div>
<h2>What carries forward</h2><ul><li>Transformation: movement, rotation, growing shots; tiles still shrink ×0.8 and turn 22.5°.</li><li>Colour: the same nine places and paths; impacts add colour.</li><li>Tiling: the same encounter; your impact still changes 18 matching floor tiles.</li><li>Refuge: larger entrance boxes shield against the higher heads and bent paths.</li></ul>
<details><summary>Before this iteration</summary><figure><img src="arrays-before.png" alt="Earlier Godot capture of the Arrays stage with a single row of three heads"><figcaption>Historical capture of the earlier three-head arrangement; camera differs.</figcaption></figure></details>
<h2>Checked in the running scene</h2><table><thead><tr><th>Check</th><th>Passed</th></tr></thead><tbody>__ROWS__</tbody></table><p class="limits">All runs exited 0. Captures use controlled Godot probes, with head motion held for comparison. Physical headset comfort, difficulty and performance are still open. Existing shutdown cleanup warnings remain. Claude’s earlier Tiling console-reach finding still needs its own fix.</p><p><a href="ARRAYS.md">Full scope and handoff</a> · <a href="arrays-evidence.json">Source hashes and evidence</a></p></main></body></html>'''.replace('__ROWS__', rows)
    (OUT / 'arrays.html').write_text(page, encoding='utf-8')
    files.append('arrays.html')
    PUBLIC.mkdir(parents=True, exist_ok=True)
    for name in files:
        shutil.copy2(OUT / name, PUBLIC / name)
    print('Published B19: arrays.html and real Godot captures')


if __name__ == '__main__':
    publish()
