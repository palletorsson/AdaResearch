"""B20/B21: publish tested Tiling feedback and the first Change biome."""
from pathlib import Path
import hashlib
import json
import shutil

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/plans/biome-ladder'
PUBLIC = ROOT.parent / 'ada_encyclopedia/public/biome-plan'


def publish():
    files = []
    for folder, names in {
        'biome_tiling_feedback': {'before.png': 'feedback-before.png', 'flash-standing.png': 'feedback-after.png', 'flash-overview.png': 'feedback-overview.png'},
        'biome_change': {'before.png': 'change-before.png', 'field-changed.png': 'change-after.png', 'turn-warning.png': 'change-warning.png'},
    }.items():
        for source, name in names.items():
            shutil.copy2(ROOT / 'ada_run' / folder / source, OUT / name)
            files.append(name)
    results = []
    for label, source, name in [
        ('Tiling access and simultaneous feedback', 'biome_tiling_feedback/report.json', 'feedback-checks.json'),
        ('Change input, field, turn and collision', 'biome_change/report.json', 'change-checks.json'),
        ('Six-stage behaviour', 'biome_ladder_play/report.json', 'change-stages-checks.json'),
        ('Arrays regression', 'biome_ladder_arrays/report.json', 'change-arrays-checks.json'),
        ('Tiling impacts regression', 'biome_tiling_floor/report.json', 'change-tiling-checks.json'),
        ('Desktop input through all stages', 'biome_ladder_play/desktop/report.json', 'change-desktop-checks.json'),
        ('Controlled XR input and falling skulls', 'biome_ladder_skull_hits/report.json', 'change-xr-checks.json'),
    ]:
        path = ROOT / 'ada_run' / source
        data = json.loads(path.read_text())
        assert data['passed'] == data['total'], label
        results.append((label, data['passed'], data['total'], name))
        shutil.copy2(path, OUT / name); files.append(name)
    museum = ROOT / 'ada_run/encounter_pilot/Flow_Field/biome-ladder-entry'
    data = json.loads((museum / 'report.json').read_text())
    assert data['passed']
    shutil.copy2(museum / 'report.json', OUT / 'change-museum-checks.json')
    shutil.copy2(museum / 'biome-entry.png', OUT / 'change-museum-entry.png')
    files += ['change-museum-checks.json', 'change-museum-entry.png']
    sources = ['commons/hazards/biome_ladder/' + n for n in
               ['route.gd', 'ladder_world.gd', 'ladder_encounter.gd', 'ladder_skull.gd',
                'ladder_ball.gd', 'change_ball.gd', 'direction_field.gd', 'pattern_flash.gdshader']]
    sources += ['tools/probes/biome_tiling_feedback.gd', 'tools/probes/biome_change.gd']
    evidence = {'date': '2026-10-13', 'iteration': 'B20/B21',
                'source_sha256': {s: hashlib.sha256((ROOT / s).read_bytes()).hexdigest() for s in sources},
                'checks': [{'name': a, 'passed': b, 'total': c, 'report': d} for a, b, c, d in results],
                'museum': '8/8 entry/dispatch checks pass, exit 0. The existing Flow_Field NOC artifact emits freed-object errors during probe cleanup; not a clean museum teardown.',
                'scope': 'Godot desktop and controlled XR input/physics. No physical headset or Quest performance acceptance.'}
    (OUT / 'change-evidence.json').write_text(json.dumps(evidence, indent=2), encoding='utf-8')
    files.append('change-evidence.json')
    table = '\n'.join(f'| {a} | [{b}/{c}]({d}) |' for a, b, c, d in results)
    report = f'''# B20/B21 — a pattern becomes a direction

13 October 2026. Palle approved fixing Tiling, then building Change. There are now six playable ladder stages. Tutorial/final.md and canonical museum order are unchanged.

## Tiling

The desktop walker and XRTools PlayerBody walk the continuous backing. Their collision exceptions exclude the 4 cm paint tiles; catalyst and skull projectiles still meet those exact transformed tile colliders. Exceptions are removed before a stage's bodies are freed. This avoids the turned edge that previously stopped the walker short of RESET, COLOUR and MENU.

A catalyst hit starts one 1.15-second white outline pulse on all 18 matching tiles in the same frame. The highlight fades; the underlying colour, scale and turn stay. Other motif addresses do not flash. RESET clears the highlight and tile state. The in-world explanation now sits on the entrance refuge, above the hand glow.

The native probe first reproduces the old obstruction with only the walking exceptions removed. With the fix, the same body walks from arrival to all 14 controls, including the new Change selector. Tile ray and projectile collision remain intact.

## Change

Play **Game menu → Biome Ladder → 6 CHANGE**, or NEXT STAGE from Tiling. The museum entry is in **Flow_Field**; MUSEUM continues to **Forces / Vectors_Act1_WhatAVectorIs**.

The floor retains scaling, rotation, colour and repeated impacts. Each tile now carries an arrow. A shot rotates the tile and its arrow together; the sampler reads that same rotation at the ball's current cell. A direction applies over its addressed cell, including gaps left by a smaller tile. Outside the floor, the forward direction is used.

The centre column introduces the new shot. It follows those arrows for 1.4 seconds at 1.8 m/s. It then samples the current target once, holds still and draws a white line for 0.9 seconds, and commits to that straight direction. Move after the signal and it continues toward the remembered position. No further homing occurs. The outer columns retain the stored zigzag paths. Row/column scheduling, falling vacancies, growing balls, cover and pickups remain.

This is prescribed motion: direction × speed × elapsed seconds updates position. Velocity is not accumulated from a force. Acceleration, mass and gravity remain for Forces. The player's catalyst edits the field through floor impacts; its own projectile retains the earlier flight behaviour.

START restores the encounter and starts volleys. REST clears shots while retaining floor edits. RESET restores the field as well as the earlier state. Stage changes still reset exact floor edits; inherited abilities remain available.

## Checks

| Runtime check | Passed |
|---|---|
{table}

The Change probe uses actual desktop input to select the stage and paint the floor. It checks the arrow/sampler reference frame, constant speed, one interval versus two half-intervals, target sampling, warning duration, committed direction, normal engine-driven flight, swept cover/player collision, REST/RESET, defeat and return to Tiling. The first phase-test failure was a test fixture: the elevated observer body still occupied the projectile path. Returning it to arrival and waiting for physics synchronization corrected the probe; the ball had correctly collided with it.

All standalone checks exit 0; existing ObjectDB cleanup warnings remain. The real museum-entry probe passes 8/8 and exits 0, but Flow_Field's older `algorithms/steering/noc_ch05/noc_5_04_flow_field_vr.gd` emits freed-label/vehicle errors during probe cleanup. This is recorded as an open museum cleanup issue, not a clean teardown. Physical headset comfort, difficulty and performance are untested.

## Claude handoff

Claude's review and probe files are untouched. Independently review whether all matching tiles are perceived as one event, whether the arrows predict the centre-column flight, and whether the one-turn cue permits a readable dodge. Update the older route probe's intentional three-head/five-stage assumptions before rerunning it. Source hashes are in [change-evidence.json](change-evidence.json). Preserve Palle's editable changes in SCAFFOLD.json. Forces is next; do not silently add acceleration to this field sampler.
'''
    (OUT / 'CHANGE.md').write_text(report, encoding='utf-8'); files.append('CHANGE.md')
    rows = ''.join(f'<tr><td>{a}</td><td><a href="{d}">{b}/{c}</a></td></tr>' for a, b, c, d in results)
    page = '''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Biome · a pattern becomes a direction</title><style>
*{box-sizing:border-box}body{margin:0;background:#f5f3ed;color:#252821;font:17px/1.6 system-ui,sans-serif}main{max-width:1280px;margin:auto;padding:38px 5vw 80px}nav{display:flex;gap:22px;flex-wrap:wrap;font-size:14px}a{color:#315e47;text-underline-offset:4px}h1{font:clamp(40px,5vw,68px)/1.08 Georgia,serif;margin:28px 0;max-width:900px}h2{font:32px/1.2 Georgia,serif;margin:42px 0 16px}.intro{max-width:850px;font-size:21px}small,figcaption{font-size:13px;color:#596454}figure{margin:26px 0}img{display:block;width:100%;height:auto;background:#252821}figcaption{margin-top:8px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:24px}.pair figure{margin:10px 0}.play{padding:20px 25px;border-left:3px solid #315e47;background:#e8ecdf;margin:28px 0}.limits{max-width:950px;font-size:14px}table{border-collapse:collapse;width:100%;max-width:850px}td,th{text-align:left;padding:10px;border-bottom:1px solid #cbd1c3}li{margin:8px 0}summary{cursor:pointer}section{scroll-margin-top:24px}@media(max-width:700px){.pair{grid-template-columns:1fr}main{padding:24px 20px}}@media print{nav{display:none}figure{break-inside:avoid}}
</style></head><body><main><nav><a href="consistency.html">Latest: state and readability</a><a href="scaffold.html#change">Edit the plan</a><a href="index.html#stage-5">Six-stage ladder</a><a href="CHANGE.md">Implementation report</a><a href="#tiling">Tiling fixes</a></nav><p><small>B20 + B21 · GODOT IMPLEMENTATION · 13 OCTOBER 2026</small></p><h1>A pattern becomes<br>a direction.</h1><p class="intro">The floor remembers the turn you gave it. In Change, that turn also tells a moving ball where to go.</p>
<figure><img src="change-after.png" alt="Actual Godot overview of the Change biome, with arrows on coloured tiles and a standing skull array"><figcaption>CHANGE · actual Godot capture after two catalyst impacts. Matching tiles turn, shrink, take colour and now redirect the centre-column balls.</figcaption></figure>
<div class="play"><b>Game menu → Biome Ladder → 6 CHANGE.</b><br>Or take NEXT STAGE from Tiling. T starts/rests, left click shoots, R resets.<br>In the museum: Flow_Field → ENTER BIOME. MUSEUM continues to Forces.</div>
<section id="change"><h2>Follow. Signal. Turn once.</h2><p>The centre column follows the floor arrows for 1.4 seconds. A ball then stops, samples your position and draws a white line for 0.9 seconds. It commits to that line. Move after the signal: it keeps the remembered direction.</p><figure><img src="change-warning.png" alt="A bright centre-column projectile holds in the air with a white line toward its sampled destination"><figcaption>The bright ball and white line announce the one turn. The outer skull columns keep their zigzag paths.</figcaption></figure><p>Speed stays constant during flight. Acceleration and gravity arrive in Forces. Your catalyst still changes the floor; the same earlier tile operations remain available.</p></section>
<section id="tiling"><h2>One hit. Eighteen answers.</h2><p>All matching Tiling tiles now flash together. The pulse fades while the colour and transformed shape stay. The player walks the continuous floor beneath them, so the turned tile edges no longer block access to the controls.</p><figure><img src="feedback-after.png" alt="Standing Godot view of the Tiling floor with all matching red tiles outlined white at once"><figcaption>TILING · one catalyst impact, one simultaneous pulse across its 18 copies.</figcaption></figure><details><summary>Earlier Tiling capture and the complete pattern</summary><div class="pair"><figure><img src="feedback-before.png" alt="Historical Tiling view before simultaneous feedback was added"><figcaption>Earlier capture; a different view and impact state.</figcaption></figure><figure><img src="feedback-overview.png" alt="Overhead view of the repeating white outline pulse across the whole Tiling floor"><figcaption>The same pulse, seen across the complete floor.</figcaption></figure></div></details></section>
<h2>What remains</h2><ul><li>Cover, moving forms, pickups and the same catalyst.</li><li>Nine addressed skulls, row/column volleys and falling vacancies.</li><li>Tile shrinking, rotation, colour and repeated patterns.</li><li>REST keeps floor edits. RESET restores them. Exact edits still reset when changing stage.</li></ul>
<h2>Runtime evidence</h2><table><thead><tr><th>Check</th><th>Passed</th></tr></thead><tbody>__ROWS__</tbody></table><p class="limits">Standalone runs exit 0; existing shutdown warnings remain. The <a href="change-museum-checks.json">museum entry and dispatch pass 8/8</a>, but the older Flow_Field artifact logs freed-object errors during cleanup. Headset comfort and performance are still untested. Captures use controlled Godot probes; they are not generated illustrations.</p><p><a href="CHANGE.md">Full report and Claude handoff</a> · <a href="change-evidence.json">Source hashes</a> · <a href="change-museum-entry.png">Entrance in Flow_Field</a></p></main></body></html>'''.replace('__ROWS__', rows)
    (OUT / 'change.html').write_text(page, encoding='utf-8'); files.append('change.html')
    PUBLIC.mkdir(parents=True, exist_ok=True)
    for name in files: shutil.copy2(OUT / name, PUBLIC / name)
    print('Published change.html: B20/Tiling and B21/Change')


if __name__ == '__main__': publish()
