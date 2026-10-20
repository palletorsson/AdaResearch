"""Publish the permanent ABM lesson table from native museum evidence."""
from pathlib import Path
import copy
import hashlib
import html
import json
import shutil
import markdown

R = Path(__file__).resolve().parents[1]
H = 'SwarmIntelligence_Agent_Based_Modeling_ABM'
O = R / 'doc/book/iterations/2026-10-11-abm-a-state-in-the-hand'
RUN = R / f'ada_run/encounter_pilot/{H}'
CODE = R / 'doc/book/iterations/2026-10-10-abm-what-the-point-carries'


def read(p):
    return json.loads(p.read_text(encoding='utf-8-sig'))


def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()


receipts = {'code': read(CODE / 'checks.json'),
            'museum': read(RUN / 'abm-table-final/report.json'),
            'portals': read(RUN / 'abm-table-portals/report.json')}
assert all(r['passed'] and all(c['passed'] for c in r['checks']) for r in receipts.values())
logs = [CODE / 'code.log'] + [RUN / tag / 'stdout.log' for tag in ['abm-table-final', 'abm-table-portals']]
for p in logs:
    log = p.read_text(encoding='utf-8')
    assert not any(s in log for s in ['SCRIPT ERROR', 'SHADER ERROR', 'blocked authored entry', 'blocked t exit']), p
preserved = read(O / 'before/preserved-hashes.json')
assert all(sha(R / p) == value for p, value in preserved.items()), 'Preserved source/text changed'
for name in ['study.tscn', 'study.gd', 'foragers.gd', 'point_body.gd']:
    assert (R / 'commons/artifacts/abm_state_table/lesson' / name).read_bytes() == (R / 'doc/book/studies/swarm-through-the-hands' / H / name).read_bytes()

old = read(O / f'before/commons/maps/{H}/map_data.json')
new = read(R / f'commons/maps/{H}/map_data.json')
expected = copy.deepcopy(old)
expected['layers']['interactables'][4][9] = ''
expected['layers']['interactables'][3][9] = 'abm_state_table:0:0:1#plinth:0#pin:1'
for x, z, token in [(1, 1, ''), (7, 8, ''), (6, 9, ''), (6, 1, 'sp'), (6, 2, 's'), (6, 8, 't')]:
    expected['layers']['utilities'][z][x] = token
expected['map_info']['museum']['portal_exit'] = {'approach': 'from_hall'}
assert new == expected, 'Undeclared map change'
old_plan = read(O / 'before/commons/data/museum/em_plan.json')
new_plan = read(R / 'commons/data/museum/em_plan.json')
expected = copy.deepcopy(old_plan)
row = next(row for row in expected['plans'] if row['map'] == H)
artifact = next(a for a in row['artifacts'] if a['token'] == 'physarum_colony')
artifact.update(token='abm_state_table', cell=[9, 3], tile_cell=[9, 3], rotation=0,
                support_height_m=0.0, config={'plinth': '0', 'pin': '1'})
artifact['ruled']['cell'] = [9, 3]
assert new_plan == expected, 'Undeclared museum-plan change'
hits = [p for p in (R / 'commons/artifacts/registry').glob('*.json')
        if 'abm_state_table' in read(p).get('artifacts', {})]
assert len(hits) == 1, hits
assert (R / read(hits[0])['artifacts']['abm_state_table']['scene'].removeprefix('res://')).is_file()

for folder in ['assets', 'evidence']:
    (O / folder).mkdir(exist_ok=True)
for view in ['above', 'room', 'table']:
    for label, tag in [('before', 'abm-table-before'), ('after', 'abm-table-final')]:
        shutil.copy2(RUN / tag / f'{view}.png', O / 'assets' / f'{view}-{label}.png')
for view in ['carrying', 'delivered', 'shared-trace', 'new-agents', 'clear-all']:
    shutil.copy2(RUN / 'abm-table-final' / f'{view}.png', O / 'assets' / f'{view}.png')
for name, tag in [('museum', 'abm-table-final'), ('portals', 'abm-table-portals')]:
    for source, suffix in [('report.json', 'checks.json'), ('stdout.log', 'log'), ('source_manifest.json', 'sources.json')]:
        shutil.copy2(RUN / tag / source, O / 'evidence' / f'{name}-{suffix}')
shutil.copy2(CODE / 'checks.json', O / 'evidence/code-checks.json')
shutil.copy2(CODE / 'code.log', O / 'evidence/code-log')
counts = {name: len(receipt['checks']) for name, receipt in receipts.items()}
total = sum(counts.values())
samples = sum(r['samples'] for r in receipts['museum']['observations']['routes'].values())
cycle = receipts['museum']['observations']['natural_cycle']

report = f'''# A state in the hand

Endless Museum · Agent-Based Modelling · 11 October 2026

The complete printed six-point study now has a permanent table in the existing ABM hall. It uses the same PointBody and byte-identical runtime copies of the three files already shown in tutorial.md. Runtime copies live under commons because packaged builds exclude doc; the publisher verifies equality. New furniture gives it a stable surface, close controls and space to approach from either side.

## The lesson

Boids asked which nearby bodies enter a calculation. Here the familiar sphere carries a Boolean state: searching or returning with food. Hold a point to pause all six, move it to FOOD, release it and press ONE TICK. A green cube appears above that same sphere. Its next request is now towards HOME, and it deposits a trace. Move it home and step again: one delivery is counted, the cube disappears and searching resumes. Let the group run, then compare REPLACE AGENTS with CLEAR ALL. New individual records can inherit the field left by the old ones. This prepares the next Ant Colony lesson, where state selects between two trace channels.

Learning elements: **individual state; contact and transition; state-dependent behaviour; shared history; two kinds of reset.** Boids was already an agent-based model; this hall isolates an additional mechanism.

## Try it

Enter **Swarm Intelligence → Agent-Based Modelling**. The table is on the right near the north entrance. Hold any sphere; trigger selects it for the readout and white ring. The four front buttons are RUN / PAUSE, ONE TICK, REPLACE AGENTS and CLEAR ALL. Walk around the sides to reach the points. Keyboard controls remain 1, 2, 3 and R.

The table starts paused. Holding a point suspends stepping for everyone. REPLACE and CLEAR refuse to run while a point is held. Release and step to make the change observable. All operations reuse the same six sphere instances.

## What remains in the room

The original colony display, navigator and full-size listening court remain. They offer richer and different encounters around one primary coding object. The unchanged final.md reflects on a changed path, on reading intention into a rule, and on what a replacement population inherits.

The unused physarum_colony placement was removed from this hall: the baseline museum loader left it uninstantiated. Its original source remains. The table takes the nearby clear bay. The hall retains its 24 × 10 layout; entry and exit markers now align with the central route. Only this hall's row in the museum plan changed.

The printed study is deliberately limited. Food is inexhaustible; contact is a distance test at the start of a tick; points can overlap and wrap at the edge. The cube records state. These choices differ from the original colony's finite food and additional behaviours and are already explained in the tutorial.

## Checks

**{total}/{total} automated checks passed:** {counts['code']} reconstructed printed-code assertions, {counts['museum']} installed-museum checks and {counts['portals']} portal checks. The code test includes an independent slower-return edit, three deliberately faulty variants and supplied XRTools inputs. The installed test uses the actual point and button methods for pickup, release, stepping, delivery and resets.

Five routes were sampled at {samples} positions for floor support and standing-capsule clearance. The portal coordinator completed ABM → Ant Colony → ABM, with supported arrivals and one resident hall. The unassisted study made {cycle['deliveries']} deliveries in {cycle['ticks']} model ticks; these ticks were stepped by the probe, not a VR frame-rate measurement.

All {len(preserved)} saved source/text hashes still match, including the original exhibits, PointBody, lesson source, sequence order and all fourteen canonical swarm texts. No tutorial or final text was rewritten. The publisher verifies the exact intended map and plan differences.

No script or shader errors appeared in the final runs. Existing UID, renderer, Jolt and viewport-texture messages remain in the logs. These are author-operated automated checks; physical headset use, Quest performance and independent student learning have not been verified.

## Images

The report contains eleven native Godot captures. Before/after pairs use the same room, overhead and table cameras. The five state photographs use one fixed view. The unrelated original colony continues running between captures. No generated illustrations substitute for the installed scene.
'''
(O / 'REPORT.md').write_text(report, encoding='utf-8')


def fig(name, caption, eager=False):
    return (f'<figure><a href="assets/{name}.png"><img src="assets/{name}.png" '
            f'alt="{html.escape(caption)}" loading="{"eager" if eager else "lazy"}"></a>'
            f'<figcaption>{html.escape(caption)}</figcaption></figure>')


css = '''*{box-sizing:border-box}body{margin:0;background:#14222c;color:#e7edef;font:17px/1.65 system-ui}nav{display:flex;flex-wrap:wrap;gap:20px;padding:17px 4vw;background:#243542}a{color:#a3dcd9}main{max-width:1460px;margin:auto;padding:36px 26px 70px}h1{font:clamp(44px,7vw,78px)/1.08 Georgia,serif;margin:18px 0;color:#f2d278}h2{font:32px Georgia,serif;margin:36px 0 16px}.eyebrow{text-transform:uppercase;font-size:13px;letter-spacing:.15em;color:#f2d278}p{max-width:980px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:18px}figure{margin:12px 0;background:#243542;padding:10px}img{display:block;width:100%}figcaption{padding:10px;font-size:14px}article{max-width:980px;margin-top:40px}strong{color:#f2d278}@media(max-width:800px){.pair{grid-template-columns:1fr}main{padding:20px 12px}}'''
body = '<p class="eyebrow">Endless Museum / Agent-Based Modelling / native Godot captures</p><h1>A state in the hand</h1><p>The same point. A carried state. A different response.</p>'
body += fig('carrying', 'Release at FOOD and step once. The green cube records carrying; this point now requests a return home.', True)
body += '<section id="lesson"><h2>What travels from Boids?</h2><p>The familiar sphere, its pickup and its trigger. Boids selected neighbours; ABM adds a state that selects behaviour. The next Ant Colony hall will use that state to choose between two trace channels.</p><p><strong>Learn:</strong> state · contact · transition · shared history · replacement versus clearing.</p></section>'
body += '<section id="states"><h2>Carry, deliver, continue</h2><div class="pair">'
body += fig('delivered', 'The same sphere moved HOME and stepped. Delivery is counted once; the cargo cube disappears.')
body += fig('shared-trace', f'After {cycle["ticks"]} unassisted model ticks: {cycle["deliveries"]} deliveries. Returning points have left marks in the shared field.') + '</div></section>'
body += '<section id="history"><h2>Two different beginnings</h2><div class="pair">'
body += fig('new-agents', 'REPLACE AGENTS restores six searching records. The field, delivery count and clock remain.')
body += fig('clear-all', 'CLEAR ALL also clears the marks, count and clock. The same six sphere instances are reused.') + '</div></section>'
for view, title, explanation in [
    ('above', 'The whole hall', 'The main route, original colony, navigator and full-size listening court remain.'),
    ('room', 'Entering the room', 'The permanent study sits in a clear bay beside the route.'),
    ('table', 'The lesson within reach', 'A solid table, four close buttons and the original printed six-point study.'),
]:
    body += f'<section id="{view}"><h2>{title}</h2><p>{explanation}</p><div class="pair">'
    body += fig(view + '-before', 'Before — same camera.') + fig(view + '-after', 'After — ' + explanation) + '</div></section>'
body += '<article id="report">' + markdown.markdown(report, extensions=['extra']) + '</article><p>'
body += ' · '.join(f'<a href="evidence/{name}-checks.json">{name.title()} checks</a>' for name in receipts) + '</p>'
page = '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>A state in the hand — ABM</title><style>' + css + '</style></head><body><nav><a href="#lesson">Lesson</a><a href="#states">State changes</a><a href="#history">Two resets</a><a href="#above">Hall / before &amp; after</a><a href="#report">Report &amp; tests</a><a href="REPORT.md">Editable report</a><a href="../2026-10-11-boids-who-enters-the-radius/index.html">Previous: Boids</a></nav><main>' + body + '</main></body></html>'
(O / 'index.html').write_text(page, encoding='utf-8')
sources = [R / f'commons/maps/{H}/map_data.json', R / 'commons/data/museum/em_plan.json',
           hits[0], R / 'tools/place_abm_state_table.py', Path(__file__)]
sources += list((R / 'commons/artifacts/abm_state_table').rglob('*'))
sources += list((R / 'tools/probes').glob('abm_table_*.gd'))
(O / 'evidence/source-hashes.json').write_text(json.dumps({p.relative_to(R).as_posix(): sha(p) for p in sources if p.is_file()}, indent=2) + '\n', encoding='utf-8')
print(f'Published {total}/{total} checks, {len(preserved)} preserved hashes, eleven native images; exact scope verified.')
