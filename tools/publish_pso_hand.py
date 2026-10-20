"""Publish the PSO control pass from real museum captures and executed checks."""
from pathlib import Path
import hashlib
import html
import json
import shutil
import markdown

R = Path(__file__).resolve().parents[1]
H = 'SwarmIntelligence_Particle_Swarm_Optimization'
O = R / 'doc/book/iterations/2026-10-11-pso-a-memory-in-hand'
RUN = R / f'ada_run/encounter_pilot/{H}'
CODE = R / 'doc/book/iterations/2026-10-10-pso-a-place-remembered'
FINAL = 'pso-hand-verified'


def read(p):
    return json.loads(p.read_text(encoding='utf-8-sig'))


def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()


receipts = {'code': read(CODE / 'checks.json'),
            'museum': read(RUN / FINAL / 'report.json'),
            'portals': read(RUN / 'pso-hand-portals/report.json')}
assert all(r['passed'] and all(c['passed'] for c in r['checks']) for r in receipts.values())
for p in [CODE / 'code.log', RUN / FINAL / 'stdout.log', RUN / 'pso-hand-portals/stdout.log']:
    log = p.read_text(encoding='utf-8')
    assert not any(s in log for s in ['SCRIPT ERROR', 'SHADER ERROR', 'blocked authored entry', 'blocked t exit']), p
preserved = read(O / 'before/preserved-hashes.json')
assert all(sha(R / p) == value for p, value in preserved.items()), 'Preserved source/text changed'
for name in ['study.gd', 'swarm.gd', 'point_body.gd']:
    assert (R / 'commons/artifacts/particle_swarm_walk' / name).read_bytes() == (R / 'doc/book/studies/swarm-through-the-hands' / H / name).read_bytes()
for folder in ['assets', 'evidence']:
    (O / folder).mkdir(exist_ok=True)
for view in ['above', 'field', 'controls']:
    for label, tag in [('before', 'pso-hand-before'), ('after', FINAL)]:
        shutil.copy2(RUN / tag / f'{view}.png', O / 'assets' / f'{view}-{label}.png')
for view in ['dock', 'memory-kept', 'memory-in-room', 'better-found', 'rule-changed', 'edge', 'ridge']:
    shutil.copy2(RUN / FINAL / f'{view}.png', O / 'assets' / f'{view}.png')
for name, tag in [('museum', FINAL), ('portals', 'pso-hand-portals')]:
    for source, suffix in [('report.json', 'checks.json'), ('stdout.log', 'log'), ('source_manifest.json', 'sources.json')]:
        shutil.copy2(RUN / tag / source, O / 'evidence' / f'{name}-{suffix}')
shutil.copy2(CODE / 'checks.json', O / 'evidence/code-checks.json')
shutil.copy2(CODE / 'code.log', O / 'evidence/code-log')
shutil.copy2(RUN / 'pso-hand-first/report.json', O / 'evidence/first-checks.json')
counts = {name: len(receipt['checks']) for name, receipt in receipts.items()}
total = sum(counts.values())
samples = sum(r['samples'] for r in receipts['museum']['observations']['routes'].values())

report = f'''# A memory in hand

Endless Museum · Particle Swarm Optimization · 11 October 2026

Take the black grip into the existing twelve-metre search field. A tilted panel shows the selected point's current coordinate and score, its remembered best in blue, and the group's best encounter in gold. Its six buttons operate the same model as the two original control banks.

## One paragraph for the lesson

Bring the familiar PointBody from Ant Colony. There, the traveller read marks left in the floor; here, each candidate keeps a scored position. Hold a sphere, select it with its trigger and move it away from its blue ring. The present coordinate changes while the old best remains. Release it and take one step: inertia, attraction to its own memory and attraction to the shared best contribute to its next displacement. Place the same sphere at a better position and step again; now the recorded position and score change together. Switch CENTER to EDGE or RIDGE and compare the new gathering. Movement is retained, but memories are evaluated afresh under the new criterion. Explain why the gold ring means best encountered under this rule, then choose another position and predict whether it will replace the selected point's record. In the next hall, the record changes again: we account for bodies arriving, disappearing and being supplied.

Learning elements: **objective function; current state versus memory; position/score pairs; personal and shared attraction; fixed shared record per iteration; changing the criterion.**

## In the museum

Enter **Swarm Intelligence → Particle Swarm Optimization**. The small black grip waits beside the entrance controls. Take it with one hand. Its trigger toggles RUN / PAUSE; the upper row offers RUN / PAUSE, ONE STEP and RESTART. The lower row chooses CENTER, EDGE or RIDGE. The selected rule lights up.

With the other hand, hold a large sphere and press its trigger to select it. Holding that candidate pauses all candidates and blocks stepping, restarting and changing the objective. Release the sphere before stepping. Holding the control grip alone does not pause the search. Drop the panel and it docks after five seconds; regrabbing cancels the return.

The small control grip is not an additional candidate. Twenty-four existing spheres remain the tutorial objects. The panel displays model coordinates in the search plane, rounded to two decimals. Floating-point negative zero is displayed as zero; underlying records remain untouched.

## What changed

Added `pso_hand_control.gd` through the existing museum wrapper: one tilted portable panel, six existing commands and a small dock. The original end controls, personal/shared rings, connecting cylinders and rear comparison exhibits remain. No map, museum-plan, sequence or canonical tutorial/final text changed. All {len(preserved)} recorded source/text hashes match. The three runtime lesson files remain byte-identical to the printed student files.

The panel reads the existing model. It does not advance the random stream, change a score or preview an uncomputed random movement. The floor cylinders join current and remembered positions; they are not ropes or the three weighted vectors of the next iteration.

## What the comparison asks

CENTER rewards proximity to the centre. EDGE rewards distance from it, which can still lead all points to one corner. RIDGE permits equally good positions along a diagonal; the shared memory can still draw candidates together. A scoring rule that permits several answers does not guarantee a varied population.

This remains close to the reflective text: the sphere is here, its remembered answer is there, and we supplied the rule that makes one answer better. The tutorial implements and tests that rule. The reflection asks what we hear in the word “best.”

## Evidence and limits

**{total}/{total} automated checks passed:** {counts['code']} exact printed-code assertions, {counts['museum']} installed-museum checks and {counts['portals']} portal checks. Printed-code checks include independent numerical expectations, a zero-social-pull variation, three executed faults and 1,800 bounded iterations across the objectives. The portable observer was also compared with an untouched model for 120 seeded iterations: positions, velocities, memories and random state matched.

Installed tests exercise the actual point and button methods: held selection, worse and better hand placements, unchanged memory until evaluation, objective changes, restart, original bank compatibility, dropped/regrabbed controls and XRTools near-grab/release with a synthetic controller. Three routes have floor support and standing-capsule clearance at {samples} sampled positions. The portal coordinator completed Particle Swarm → Population Support → Particle Swarm, with supported arrivals and one resident hall.

The first run caught the displayed minus-zero mismatch. The panel now normalizes zero at display precision. Native image review also prompted larger text, a 25-degree panel tilt and moving the dock instruction beside it so it does not cover the readout. The first failed receipt is retained.

Final runs contain no script or shader errors. Existing UID, Jolt, renderer and loading messages remain in the logs. This is author-operated automated verification, not a physical-headset test, Quest performance measurement or independent learner trial.

Thirteen native Godot captures show the installed museum. Before/after views use identical cameras and the same six-step CENTER state. Optional comparisons run independently. The three close-up records use the same camera: a worse placement, a better placement after stepping, and then a changed objective. Those interventions are deliberately staged through the same point/command interfaces used by the visitor.
'''
(O / 'REPORT.md').write_text(report, encoding='utf-8')


def fig(name, caption, eager=False):
    return (f'<figure><a href="assets/{name}.png"><img src="assets/{name}.png" '
            f'alt="{html.escape(caption)}" loading="{"eager" if eager else "lazy"}"></a>'
            f'<figcaption>{html.escape(caption)}</figcaption></figure>')


css = '''*{box-sizing:border-box}body{margin:0;background:#14222c;color:#e7edef;font:17px/1.65 system-ui}nav{display:flex;flex-wrap:wrap;gap:20px;padding:17px 4vw;background:#243542}a{color:#a3dcd9}main{max-width:1460px;margin:auto;padding:36px 26px 70px}h1{font:clamp(44px,7vw,78px)/1.08 Georgia,serif;margin:18px 0;color:#f2d278}h2{font:32px Georgia,serif;margin:36px 0 16px}.eyebrow{text-transform:uppercase;font-size:13px;letter-spacing:.15em;color:#f2d278}p{max-width:980px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:18px}figure{margin:12px 0;background:#243542;padding:10px}img{display:block;width:100%}figcaption{padding:10px;font-size:14px}article{max-width:980px;margin-top:40px}strong{color:#f2d278}@media(max-width:800px){.pair{grid-template-columns:1fr}main{padding:20px 12px}}'''
body = '<p class="eyebrow">Endless Museum / Particle Swarm / native Godot captures</p><h1>A memory in hand</h1><p>The sphere is here. Its remembered answer is there.</p>'
body += fig('memory-kept', 'The selected sphere has moved to (6, 6), scoring −72. Its blue record still keeps the earlier, better encounter.', True)
body += '<section id="memory"><h2>One point, a different record</h2><p>Moving changes the candidate. Stepping evaluates it. Changing the objective starts new best records.</p><div class="pair">'
body += fig('better-found', 'After placing the same point at the centre and stepping: personal and shared best score zero.')
body += fig('rule-changed', 'Switch to EDGE: the current bodies and movement are kept, but all best records are re-evaluated.') + '</div>'
body += fig('memory-in-room', 'The existing blue and gold rings make the remembered destinations spatially visible.') + '</section>'
body += '<section id="hand"><h2>Take the scores with you</h2><p>Six controls, one existing search model. Select a sphere with its held trigger; release it before taking a step.</p>'
body += fig('dock', 'The same small PointBody grip carries the panel. It docks here five seconds after release.') + '</section>'
body += '<section id="rules"><h2>Which question are we asking?</h2><div class="pair">'
body += fig('edge', 'EDGE rewards distance from the centre. It does not reward distance from other candidates.')
body += fig('ridge', 'RIDGE gives a diagonal equal value. The group can still gather at one remembered answer.') + '</div></section>'
for view, title, description in [
    ('above', 'The hall from above', 'The full-size field, clear passage and rear comparisons remain.'),
    ('field', 'Inside the search', 'The same twenty-four PointBody spheres and the same score field.'),
    ('controls', 'Both end controls remain', 'The portable panel calls their existing commands.'),
]:
    body += f'<section id="{view}"><h2>{title}</h2><p>{description}</p><div class="pair">'
    body += fig(view + '-before', 'Before — same camera and six-step CENTER state.')
    body += fig(view + '-after', 'After — ' + description) + '</div></section>'
body += '<article id="report">' + markdown.markdown(report, extensions=['extra']) + '</article><p>'
body += ' · '.join(f'<a href="evidence/{name}-checks.json">{name.title()} checks</a>' for name in receipts) + '</p>'
body += '<p><a href="evidence/first-checks.json">First-run failure</a> · <a href="before/preserved-hashes.json">Preserved sources</a></p>'
page = '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>A memory in hand — Particle Swarm</title><style>' + css + '</style></head><body><nav><a href="#memory">Memory</a><a href="#hand">Hand controls</a><a href="#above">Before &amp; after</a><a href="#report">Report &amp; tests</a><a href="REPORT.md">Editable report</a><a href="../2026-10-11-colony-the-channels-in-hand/index.html">Previous: Ant Colony</a><a href="../../../../commons/maps/' + H + '/tutorial.md">Full tutorial</a><a href="../../../../commons/maps/' + H + '/final.md">Reflective text</a></nav><main>' + body + '</main></body></html>'
(O / 'index.html').write_text(page, encoding='utf-8')
sources = [Path(__file__), R/'commons/maps'/H/'map_data.json', R/'commons/data/museum/em_plan.json']
sources += list((R/'commons/artifacts/particle_swarm_walk').glob('*'))
sources += list((R/'tools/probes').glob('pso_hand_*.gd'))
(O/'evidence/source-hashes.json').write_text(json.dumps({p.relative_to(R).as_posix():sha(p) for p in sources if p.is_file()},indent=2)+'\n',encoding='utf-8')
print(f'Published {total}/{total} checks, {len(preserved)} preserved hashes, thirteen native images.')
