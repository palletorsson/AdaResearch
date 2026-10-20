"""Publish the scoped Random Space passage repair and its native evidence."""
from pathlib import Path
import hashlib
import html
import json
import shutil
import zipfile

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-09-random-space-exit'
RUNS = ROOT / 'ada_run/encounter_pilot/Random_Space'
OUT.mkdir(parents=True, exist_ok=True)

results = {}
for label, run in [('desktop', 'exit-desktop-walk-2'), ('xr', 'exit-xr-walk')]:
    src = RUNS / run
    receipt = json.loads((src / 'report.json').read_text(encoding='utf-8'))
    log = (src / 'stdout.log').read_text(encoding='utf-8')
    assertions = [line[len('[passage] '):] for line in log.splitlines() if line.startswith('[passage] ')]
    assert receipt['passed'] and not receipt['failures']
    assert all(line.startswith('PASS ') for line in assertions)
    receipt['assertions'] = assertions
    receipt['assertion_count'] = len(assertions)
    receipt['scope'] = ('Real museum and physics body. Supplied scanner access, horizontal velocity, '
                        'swept forward crossing and requested return. XR camera pose is simulated; '
                        'not a headset or a complete fourteen-hall walking test.')
    dst = OUT / label
    dst.mkdir(exist_ok=True)
    (dst / 'report.json').write_text(json.dumps(receipt, indent=2), encoding='utf-8')
    for name in ['engine.log', 'stdout.log', 'source_manifest.json', 'spec.json', 'museum_snapshot.gd']:
        shutil.copy2(src / name, dst / name)
    results[label] = {'passed': True, 'checks': len(assertions)}

for label, run in [('before', 'exit-before'), ('geometry', 'exit-final-view'),
                   ('attempt-raised', 'exit-desktop'), ('attempt-checker', 'exit-desktop-walk')]:
    dst = OUT / label
    dst.mkdir(exist_ok=True)
    for name in ['report.json', 'engine.log', 'stdout.log']:
        if (RUNS / run / name).is_file():
            shutil.copy2(RUNS / run / name, dst / name)
shutil.copy2(RUNS / 'exit-before/rear-overview.png', OUT / 'before.png')
shutil.copy2(RUNS / 'exit-final-view/rear-overview.png', OUT / 'after.png')

sources = {}
reproduce = OUT / 'reproduce'
reproduce.mkdir(exist_ok=True)
for path in ['tools/probes/random_space_passage.gd', 'tools/probes/hall_portal_navigation.gd',
             'tools/probes/random_space_exit.gd', 'tools/probes/transformation_encounters.gd',
             'tools/run_encounter_probe.py', 'commons/scenes/em/em_portal_stream.gd',
             'commons/scenes/em/em_portal_frame.gd', 'commons/maps/Random_Space/map_data.json',
             'commons/maps/Random_Game/map_data.json']:
    source = ROOT / path
    sources[path] = hashlib.sha256(source.read_bytes()).hexdigest()
    shutil.copy2(source, reproduce / path.replace('/', '__'))
(OUT / 'validation.json').write_text(json.dumps({'runs': results, 'sources': sources}, indent=2), encoding='utf-8')

report = '''# Random Space — a supported way onward

The remaining exit problem from the Randomness ghost-student report is repaired. The native round trip **Random Space → Random Game → Random Space** passes **49 desktop checks and 50 checks with the XR player body**.

## The change

The terrain intersected the old floor-level doorway. I joined the rear blocks into a three-metre-wide, one-metre-high landing, added three adjacent ramp wedges, and moved the exit one cell inward to clear the rear boundary wall. The doorway faces the approaching visitor.

This is a change to `commons/maps/Random_Space/map_data.json`: seven structure cells, three ramp utilities, the exit's cell and its approach setting. The hall derives its geometry from that file on load. All five authored exhibits, their positions and parameters are retained. No artifact algorithm, portal runtime, lesson, reflection or sequence order was changed in this repair.

## What ran

- Both runs load the actual museum and settle the real player body under gravity at three arrivals.
- The body walks a supported route from each entrance. The test supplies the existing scanner's access action and horizontal velocity; movement meets the live colliders.
- A swept doorway crossing loads Random Game. A return request restores Random Space. Only one hall remains resident, and arrival does not immediately send the player back.
- On return, the body walks down the ramp onto the terrain and climbs back to the landing without jumping or teleporting along the route.
- The XR run uses the actual XR Tools player body, a simulated room-scale camera offset and the bounds checker. It is not a physical headset session.

## What the failures taught us

The first raised doorway was still too close to the museum's rear boundary wall. The first round trip succeeded but the clearance check exposed that edge; moving the exit inward fixed it. The old flat-floor checker also asked for a straight, level line from entrances where the safe route turns or follows terrain. A floor ray landing exactly on a shared block edge returned a side normal. I retained that failed receipt and used actual body walks to test the passage instead. The new checker initially had a GDScript type-inference error; its failed launch is retained too.

The final tests have no script errors. Existing missing-UID and shutdown-leak warnings remain in the logs. The coarse inventory walk graph still calls this hall severed because it reserves the terrain's footprint; the native player checks demonstrate the tested paths through its actual collision surface. That graph is not repaired here.

## Reading status

The previous **420 baseline and 60 changed-program checks** still stand as the teaching evidence; this map-only repair does not require a tutorial rewrite. Randomness keeps its fourteen-hall order, with the closing Biome Ladder deferred. This pass closes the reported exit issue. It does not certify a continuous walk through the whole sequence or headset comfort.

## Reproduce

From the repository root:

```powershell
python -X utf8 tools/run_encounter_probe.py Random_Space --sequence randomness --render --output-tag exit-desktop-review --probe tools/probes/random_space_passage.gd --spec doc/book/iterations/2026-10-09-random-space-exit/desktop-spec.json
python -X utf8 tools/run_encounter_probe.py Random_Space --sequence randomness --render --output-tag exit-xr-review --probe tools/probes/random_space_passage.gd --spec doc/book/iterations/2026-10-09-random-space-exit/xr-spec.json
```

[Desktop receipt](desktop/report.json) · [XR receipt](xr/report.json) · [Source hashes](validation.json) · [Previous ghost-student report](../2026-10-09-randomness-ghost-student/index.html)
'''
(OUT / 'REPORT.md').write_text(report, encoding='utf-8')
page = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Random Space — a supported way onward</title><style>
body{margin:0;background:#f5f2ec;color:#26212a;font:18px/1.65 Georgia,serif}main{max-width:1150px;margin:auto;padding:36px 28px}h1{font-size:clamp(32px,4.6vw,58px);line-height:1.1}h2{margin-top:2em;font-size:27px}p{max-width:850px}a{color:#882f57}nav,figcaption,.meta{font:14px/1.5 system-ui}nav{display:flex;flex-wrap:wrap;gap:18px;border-bottom:1px solid #cfc6bf;padding-bottom:20px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:20px}figure{margin:0}img{display:block;width:100%;height:auto}figcaption{padding:10px 0;color:#5b5155}.status{padding:18px 22px;background:#e6eddf;border-left:4px solid #5b7242}.receipts{display:flex;gap:18px;flex-wrap:wrap}details{border-top:1px solid #cfc6bf;margin-top:26px;padding-top:18px}li{max-width:850px;margin-bottom:8px}@media(max-width:750px){.pair{grid-template-columns:1fr}main{padding:22px}}
</style><main><nav><a href="../2026-10-09-randomness-ghost-student/index.html">Ghost-student report</a><a href="REPORT.md">Full repair notes</a><a href="random-space-passage.zip">Repair packet</a></nav>
<h1>A supported way onward</h1><p class="meta">Random Space → Random Game · Native museum repair · 9 October 2026</p>
<p class="status"><strong>49 desktop checks + 50 XR-body checks pass.</strong><br>The player reaches the next hall, returns, and walks down and up the new ramp.</p>
<p>The terrain cut through the old exit. A broad ramp now joins it to a level landing. The doorway stands one cell inward, clear of the rear wall.</p>
<div class="pair"><figure><a href="before.png"><img src="before.png" alt="Before: purple terrain crosses the broken rear floor and no exit doorway appears"></a><figcaption>Before: the terrain prevents the floor-level doorway from being placed.</figcaption></figure><figure><a href="after.png"><img src="after.png" alt="After: three adjacent ramps lead to a level platform and a pink portal marked Random Game"></a><figcaption>After: a three-metre-wide ramp and level landing support the Random Game exit. Captured inside Godot.</figcaption></figure></div>
<h2>The player test</h2><ul><li>Load Random Space; settle and walk away from the entrance.</li><li>Cross into Random Game; settle and walk into its hall.</li><li>Return to Random Space; descend to the terrain and climb back without jumping.</li><li>Verify one resident hall, solid arrival and no immediate return loop.</li></ul>
<p>The XR run uses the real XR Tools player body with a simulated headset offset. Access and locomotion inputs are supplied by the test. Headset comfort and a continuous walk through all fourteen halls remain untested.</p>
<div class="receipts"><a href="desktop/report.json">49 desktop assertions</a><a href="xr/report.json">50 XR-body assertions</a><a href="validation.json">Evidence and source hashes</a></div>
<h2>What this means for the book</h2><p>The tutorial and reflective texts keep their current wording and order. The previous 480 learner-code checks remain the teaching evidence. This repair makes the reported passage work in the museum; it adds no new programming subject.</p>
<details><summary>What changed, and what remains</summary><p>One map file: seven structure cells, three ramp utilities, an exit moved one cell inward and its approach direction. All five authored exhibits retain their positions and settings. No runtime algorithm changed.</p><p>The first repair and checker failures are preserved in the <a href="REPORT.md">full notes</a>. Existing UID and shutdown warnings remain. The coarse inventory route graph still reserves the terrain as an obstacle; these tests instead follow its actual collision surface.</p></details></main></html>'''
(OUT / 'index.html').write_text(page, encoding='utf-8')

old = ROOT / 'doc/book/iterations/2026-10-09-randomness-ghost-student/index.html'
s = old.read_text(encoding='utf-8')
marker = '<!-- passage-repair-followup -->'
if marker not in s:
    insert = marker + '<p style="padding:16px;background:#e6eddf"><strong>Follow-up:</strong> The remaining Random Space exit is now repaired. <a href="../2026-10-09-random-space-exit/index.html">See the native captures and 99 passage checks</a>.</p>'
    s = s.replace('<h2>What I changed</h2>', insert + '<h2>What I changed</h2>')
    old.write_text(s, encoding='utf-8')
old_md = ROOT / 'doc/book/iterations/2026-10-09-randomness-ghost-student/REPORT.md'
s = old_md.read_text(encoding='utf-8')
if '2026-10-09-random-space-exit' not in s:
    s += '\n\n## Follow-up: passage repaired\n\nThe exit issue recorded above is resolved in the [native passage repair](../2026-10-09-random-space-exit/index.html): 49 desktop and 50 XR-body checks pass. The earlier report and its ZIP preserve their original test scope.\n'
    old_md.write_text(s, encoding='utf-8')
with zipfile.ZipFile(OUT / 'random-space-passage.zip', 'w', zipfile.ZIP_DEFLATED) as archive:
    for p in OUT.rglob('*'):
        if p.is_file() and p.suffix != '.zip': archive.write(p,p.relative_to(OUT))
print(json.dumps(results))
print(OUT / 'index.html')
