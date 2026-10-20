"""Publish the Boids neighbour encounter from native evidence; verify edit scope."""
from pathlib import Path
import copy
import hashlib
import html
import json
import shutil
import markdown

R = Path(__file__).resolve().parents[1]
O = R / 'doc/book/iterations/2026-10-11-boids-who-enters-the-radius'
H = 'SwarmIntelligence_Boids_Algorithm'
RUN = R / f'ada_run/encounter_pilot/{H}'


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


receipts = {
    'code': read(R / 'ada_run/boids_lens_checks.json'),
    'museum': read(RUN / 'boids-lens-final/report.json'),
    'portals': read(RUN / 'boids-lens-portals/report.json'),
}
assert all(r['passed'] and all(c['passed'] for c in r['checks']) for r in receipts.values())
logs = [R / 'ada_run/boids-lens-checks.log'] + [
    RUN / tag / 'stdout.log' for tag in ['boids-lens-final', 'boids-lens-portals']
]
for path in logs:
    log = path.read_text(encoding='utf-8')
    assert not any(s in log for s in ['SCRIPT ERROR', 'SHADER ERROR', 'blocked authored entry', 'blocked t exit']), path
preserved = read(O / 'before/preserved-hashes.json')
assert all(sha(R / p) == value for p, value in preserved.items()), 'Preserved source or text changed'

old = read(O / f'before/commons/maps/{H}/map_data.json')
new = read(R / f'commons/maps/{H}/map_data.json')
expected = copy.deepcopy(old)
for x, z in [(6, 3), (9, 7)]:
    expected['layers']['structure'][z][x] = '1'
for x, z, token in [(1, 1, ''), (10, 11, ''), (6, 12, ''), (6, 1, 'sp'), (6, 2, 's'), (6, 11, 't')]:
    expected['layers']['utilities'][z][x] = token
expected['layers']['interactables'][9][10] = ''
expected['layers']['interactables'][3][9] = 'boids_neighbour_lens:0:0:1#plinth:0#pin:1'
expected['map_info']['museum']['portal_exit'] = {'approach': 'from_hall'}
expected['map_info']['museum']['sculpture_clear_rects'] = [[1, 1, 12, 12], [0, 9, 3, 11], [11, 1, 27, 12]]
assert new == expected, 'Undeclared map change'

old_plan = read(O / 'before/commons/data/museum/em_plan.json')
new_plan = read(R / 'commons/data/museum/em_plan.json')
expected = copy.deepcopy(old_plan)
row = next(row for row in expected['plans'] if row['map'] == H)
row['tile'] = [['4' if c == 'w' else '0' if not c else c for c in cells] for cells in new['layers']['structure']]
row['interior_count'] = sum(c == '1' for cells in row['tile'] for c in cells)
artifact = next(a for a in row['artifacts'] if a['token'] == 'flocking_controls')
artifact.update(token='boids_neighbour_lens', cell=[9, 3], tile_cell=[9, 3], rotation=0,
                support_height_m=0.0, config={'plinth': '0', 'pin': '1'})
artifact['ruled']['cell'] = [9, 3]
assert new_plan == expected, 'Undeclared museum-plan change'
hits = [p for p in (R / 'commons/artifacts/registry').glob('*.json')
        if 'boids_neighbour_lens' in read(p).get('artifacts', {})]
assert len(hits) == 1, hits
entry = read(hits[0])['artifacts']['boids_neighbour_lens']
assert (R / entry['scene'].removeprefix('res://')).is_file()

for folder in ['assets', 'evidence']:
    (O / folder).mkdir(exist_ok=True)
for view in ['above', 'room', 'controls']:
    for label, tag in [('before', 'boids-lens-before'), ('after', 'boids-lens-final')]:
        shutil.copy2(RUN / tag / f'{view}.png', O / 'assets' / f'{view}-{label}.png')
for view in ['narrow', 'wide', 'separation-off', 'hand-controls']:
    shutil.copy2(RUN / 'boids-lens-final' / f'{view}.png', O / 'assets' / f'{view}.png')
for name, tag in [('museum', 'boids-lens-final'), ('portals', 'boids-lens-portals')]:
    for source, suffix in [('report.json', 'checks.json'), ('stdout.log', 'log'), ('source_manifest.json', 'sources.json')]:
        shutil.copy2(RUN / tag / source, O / 'evidence' / f'{name}-{suffix}')
shutil.copy2(R / 'ada_run/boids_lens_checks.json', O / 'evidence/code-checks.json')
shutil.copy2(R / 'ada_run/boids-lens-checks.log', O / 'evidence/code-log')
counts = {name: len(receipt['checks']) for name, receipt in receipts.items()}
total = sum(counts.values())
samples = sum(r['samples'] for r in receipts['museum']['observations']['routes'].values())
comparison = receipts['museum']['observations']['radius_comparison']

report = f'''# Who enters the radius?

Endless Museum · Boids · 11 October 2026

The familiar point now changes who counts as a neighbour. The original thirty-body FlockingControls exhibit has moved into a clear bay, with a visible radius, links to the selected neighbours and four arrows showing the requests for one body.

## Try it in the museum

Enter **Swarm Intelligence → Boids**. The table is near the north entrance, on the right. Pick up the black point from its left stand. Press its trigger to pause, then move your hand left or right. The bodies stay where they are while the gold radius contracts or expands. Watch the neighbour count and the requests change. Press again to let the same bodies continue.

The nearby right button also pauses and plays. The original separation, alignment, cohesion, speed and radius sliders remain accessible at the front. Dropping the point returns it to its stand after 1.5 seconds; your chosen radius stays. Reset makes a new random scatter.

## What this comparison makes visible

In the captured comparison, a radius of 0.05 m includes **{comparison['small']} neighbours** and 0.5 m includes **{comparison['large']}**. Positions and velocities are identical in both photographs. The changing count comes entirely from the inclusion radius. This particular count is a recorded example, not a fixed result for every run.

Red shows separation, blue alignment, green cohesion, and white their sum. These are the next weighted steering requests for the gold body, before the original speed limits. Arrow lengths are compressed to fit the table; the labels give full magnitudes. Setting the original separation slider to zero removes that request without moving the paused bodies.

Flow Fields supplied a direction at each location. Here the other bodies help determine the next request, but only if they enter the chosen radius. In the next hall, Agent-Based Modelling, we ask what the individual point carries as its own state. The point remains our means of intervening in the example; it is not added to the flock as another neighbour.

## Space and continuity

- Moved FlockingControls from cell (10, 9) to (9, 3), with a solid table and two nearby hand controls. Its original scene remains inside the new adapter.
- Cleared two interior posts and aligned entry/exit with the north/south openings. Kept the 28 × 13 hall dimensions, west observation balcony and east drone court.
- Kept the open hundred-body flock, seventy-two-fish school, aquarium, film, 2D panel, science display and drone comparison. The route to the balcony passes around the existing 2D panel.
- Preserved all fourteen canonical swarm tutorial/reflection texts, the sequence order, the PointBody class and the original simulation sources. Only this hall's row of the museum plan changed.

The printed tutorial remains the small snapshot/fixed-step study already written. This optional exhibit runs the original sequential, frame-driven FlockingControls model. Their implementation differences remain explicit.

## Checks and limits

**{total}/{total} automated checks passed:** {counts['code']} production-code checks, {counts['museum']} installed-museum checks and {counts['portals']} portal checks.

The adapter and an unwrapped original produced exactly matching positions and velocities over 300 varying time steps. Additional checks compare the preview with the original body's next calculation, verify rendered link endpoints, and exercise pause/resume, old sliders, drop/return and supplied desktop/XR near-grab inputs.

The museum probe sampled {samples} positions along five routes for floor support and standing-capsule clearance. A native paused comparison verified that radius changes preserve every position and velocity, while the visible rings, links and arrows match the calculation. The portal coordinator completed Boids → Agent-Based Modelling → Boids using supplied crossing requests, with supported arrivals and one resident hall.

All {len(preserved)} recorded source/text hashes match. The publisher also checks the exact intended map and plan changes. Final runs contain no script or shader errors. The logs retain UID, renderer and Jolt warnings/errors; the portal run also reports viewport-texture errors during loading. These remain outside this exhibit's checks. Physical headset interaction and Quest performance have not been tested.

The first attempts revealed an inherited panel hidden by the new table and a balcony test route running through the old 2D panel. Raising the control panel and routing around the existing exhibit resolved those checks. The report uses the final native captures.

## Photographs

Room and overhead before/after views use the same cameras in the real Godot museum. Control close-ups use the same view relative to the exhibit, which has moved. Running simulation states differ; the narrow/wide pair specifically keeps the same paused state. These are engine captures, not illustrated proposals.
'''
(O / 'REPORT.md').write_text(report, encoding='utf-8')

css = '''*{box-sizing:border-box}body{margin:0;background:#14222c;color:#e7edef;font:17px/1.65 system-ui}nav{display:flex;flex-wrap:wrap;gap:20px;padding:17px 4vw;background:#243542}a{color:#a3dcd9}main{max-width:1460px;margin:auto;padding:36px 26px 70px}h1{font:clamp(44px,7vw,78px)/1.08 Georgia,serif;margin:18px 0;color:#f2d278}h2{font:32px Georgia,serif;margin:36px 0 16px}.eyebrow{text-transform:uppercase;font-size:13px;letter-spacing:.15em;color:#f2d278}p{max-width:980px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:18px}figure{margin:12px 0;background:#243542;padding:10px}img{display:block;width:100%}figcaption{padding:10px;font-size:14px}article{max-width:980px;margin-top:40px}strong{color:#f2d278}@media(max-width:800px){.pair{grid-template-columns:1fr}main{padding:20px 12px}}'''


def fig(name, caption, eager=False):
    return (f'<figure><a href="assets/{name}.png"><img src="assets/{name}.png" '
            f'alt="{html.escape(caption)}" loading="{"eager" if eager else "lazy"}"></a>'
            f'<figcaption>{html.escape(caption)}</figcaption></figure>')


body = '<p class="eyebrow">Endless Museum / Boids / native Godot captures</p><h1>Who enters the radius?</h1><p>Hold the same point. Pause the flock. Change who counts as a neighbour.</p>'
body += fig('hand-controls', 'The installed encounter: the point at left changes radius; the nearby right button pauses and resumes.', True)
body += '<section id="radius"><h2>The same moment, two radii</h2><p>Only the radius changes. All thirty positions and velocities stay the same.</p><div class="pair">'
body += fig('narrow', f'0.05 m — {comparison["small"]} neighbours of the gold body.')
body += fig('wide', f'0.5 m — {comparison["large"]} neighbours of the same body.') + '</div></section>'
body += '<section id="requests"><h2>Three requests, one sum</h2><p>Red: separation. Blue: alignment. Green: cohesion. White: sum. The numerical magnitudes remain exact; arrow lengths are compressed for display.</p>'
body += fig('separation-off', 'Separation set to zero using the original slider. The paused bodies have not moved.') + '</section>'
for view, title, explanation in [
    ('above', 'From above', 'The original open flock, west fish balcony and east drone court remain. Two posts are removed from the central routes.'),
    ('room', 'A clear bay', 'The unchanged FlockingControls scene now sits near the entrance. Room views use the same camera.'),
    ('controls', 'Controls within reach', 'Close-ups use the same camera relative to the exhibit. The original panel now sits above the table, with the point and pause button beside it.'),
]:
    body += f'<section id="{view}"><h2>{title}</h2><p>{explanation}</p><div class="pair">'
    body += fig(view + '-before', 'Before — ' + explanation) + fig(view + '-after', 'After — ' + explanation) + '</div></section>'
body += '<article id="report">' + markdown.markdown(report, extensions=['extra']) + '</article><p>'
body += ' · '.join(f'<a href="evidence/{name}-checks.json">{name.title()} checks</a>' for name in receipts) + '</p>'
page = '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Who enters the radius? — Boids</title><style>' + css + '</style></head><body><nav><a href="#radius">Two radii</a><a href="#requests">Three requests</a><a href="#above">Above / before &amp; after</a><a href="#controls">Controls</a><a href="#report">Report &amp; tests</a><a href="REPORT.md">Editable report</a><a href="../2026-10-11-flow-room-to-move/index.html">Previous: Flow Fields</a></nav><main>' + body + '</main></body></html>'
(O / 'index.html').write_text(page, encoding='utf-8')
sources = [R / f'commons/maps/{H}/map_data.json', R / 'commons/data/museum/em_plan.json',
           hits[0], R / 'tools/place_boids_lens.py', Path(__file__)]
sources += list((R / 'commons/artifacts/boids_neighbour_lens').glob('*'))
sources += list((R / 'tools/probes').glob('boids_lens_*.gd'))
(O / 'evidence/source-hashes.json').write_text(json.dumps({p.relative_to(R).as_posix(): sha(p) for p in sources if p.is_file()}, indent=2) + '\n', encoding='utf-8')
print(f'Published {total}/{total} checks, {len(preserved)} preserved hashes, ten native images; exact scope verified.')
