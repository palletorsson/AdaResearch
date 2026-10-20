"""Publish the Ant Colony hand control using native museum evidence."""
from pathlib import Path
import hashlib
import html
import json
import shutil
import markdown

R = Path(__file__).resolve().parents[1]
H = 'SwarmIntelligence_Ant_Colony_Optimization'
O = R / 'doc/book/iterations/2026-10-11-colony-the-channels-in-hand'
RUN = R / f'ada_run/encounter_pilot/{H}'
CODE = R / 'doc/book/iterations/2026-10-10-colony-two-trails-underfoot'


def read(p):
    return json.loads(p.read_text(encoding='utf-8-sig'))


def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()


receipts = {'code': read(CODE / 'checks.json'),
            'museum': read(RUN / 'colony-hand-verified/report.json'),
            'portals': read(RUN / 'colony-hand-portals/report.json')}
assert all(r['passed'] and all(c['passed'] for c in r['checks']) for r in receipts.values())
for p in [CODE / 'code.log'] + [RUN / tag / 'stdout.log' for tag in ['colony-hand-verified', 'colony-hand-portals']]:
    log = p.read_text(encoding='utf-8')
    assert not any(s in log for s in ['SCRIPT ERROR', 'SHADER ERROR', 'blocked authored entry', 'blocked t exit']), p
preserved = read(O / 'before/preserved-hashes.json')
assert all(sha(R / p) == value for p, value in preserved.items()), 'Preserved source/text changed'
for folder in ['assets', 'evidence']:
    (O / folder).mkdir(exist_ok=True)
for view in ['above', 'field', 'controls']:
    for label, tag in [('before', 'colony-hand-before'), ('after', 'colony-hand-verified')]:
        shutil.copy2(RUN / tag / f'{view}.png', O / 'assets' / f'{view}-{label}.png')
for view in ['dock', 'search', 'returning']:
    shutil.copy2(RUN / 'colony-hand-verified' / f'{view}.png', O / 'assets' / f'{view}.png')
for name, tag in [('museum', 'colony-hand-verified'), ('portals', 'colony-hand-portals')]:
    for source, suffix in [('report.json', 'checks.json'), ('stdout.log', 'log'), ('source_manifest.json', 'sources.json')]:
        shutil.copy2(RUN / tag / source, O / 'evidence' / f'{name}-{suffix}')
shutil.copy2(CODE / 'checks.json', O / 'evidence/code-checks.json')
shutil.copy2(CODE / 'code.log', O / 'evidence/code-log')
shutil.copy2(RUN / 'colony-hand-final/report.json', O / 'evidence/first-route-checks.json')
counts = {name: len(receipt['checks']) for name, receipt in receipts.items()}
total = sum(counts.values())
samples = sum(r['samples'] for r in receipts['museum']['observations']['routes'].values())

report = f'''# The channels in hand

Endless Museum · Ant Colony · 11 October 2026

Carry a small control pad into the existing twelve-metre colony. Its black grip uses the familiar PointBody. The pad shows the selected agent's state, the channel it reads, the channel it leaves, and its three sensor values. You can now pause and step beside the point you are inspecting.

## One paragraph for the lesson

Bring the sphere and carrying state from ABM. Previously the returner knew the home coordinate. Here it reads nearby marks: searching reads food and leaves home; carrying reads home and leaves food. Pick up a sphere, select it with its trigger, move it to FOOD and release. ONE TICK switches its state and reverses the read/write roles. Follow its next three samples, then compare replacing the population with clearing both fields. The same body can read what another body left. In Particle Swarm, which follows, the question will change again: a point keeps a scored position as a memory of its own best encounter.

Learning elements: **two channels; state chooses read/write; local sampling; reinforcement and evaporation; inherited traces.** The pad exposes the existing rule; it adds no algorithm to the lesson.

## In the museum

Enter **Swarm Intelligence → Ant Colony Optimization**. Take the black grip beside the entrance control bank. Carry it into the field. Its trigger toggles RUN / PAUSE; its four buttons operate RUN / PAUSE, ONE TICK, REPLACE POINTS and CLEAR ALL. The original controls at both ends remain active.

Use the other hand to hold a colony sphere and press its trigger to select it. The pad follows that record. Holding a colony point pauses all agents and blocks stepping and resets; release the agent before pressing ONE TICK. Holding the control grip alone does not pause the model. Dropping the pad leaves it where it was for five seconds, then docks it. Regrabbing cancels the return.

The black control grip is not another colony agent. Its movement does not add marks to the floor. Twenty-four existing colony spheres remain the tutorial objects. The two displayed strips are two values at one address, not physical lanes.

## What changed

Added one portable pad and a small dock through the museum wrapper. Kept the exact printed study, its model and PointBody, the original end controls, the twelve-metre field and the east three-size ant gallery. No map, museum-plan, sequence, tutorial or final text changed. All {len(preserved)} recorded source/text hashes match.

The reflective text still follows what a traveller inherits and what standing inside the model does not let us change. The foot cannot erase a mark here. The hand can move a point; the new pad lets us inspect what that intervention does next.

## Evidence and limits

**{total}/{total} automated checks passed:** {counts['code']} exact printed-code assertions, {counts['museum']} installed-museum checks and {counts['portals']} portal checks. Code checks include an independent half-deposit variation and three executed faults. Native checks use the actual grip and button methods, verify displayed readings against the model, exercise held-agent protections, test replacement versus clearing and test supplied XRTools near-grab/release.

Three routes were checked at {samples} positions for floor support and standing-capsule clearance. The first proposed route crossed the ant atlas's existing control stand. The corrected route goes around it; the first failure is retained in evidence. The portal coordinator completed Ant Colony → Particle Swarm → Ant Colony with supported arrivals and one resident hall.

Final runs have no script or shader errors. Existing UID, Jolt, renderer and loading messages remain in the saved logs. These are automated author-operated checks, not a physical-headset test, Quest performance measurement or independent learner trial.

Nine native Godot captures show the installed scene. Before/after views use the same cameras and the same 260-tick lesson state. The optional ant atlas advances independently, so its pictures differ. The SEARCH/RETURN pair uses one camera beside FOOD; the selected agent is released and one tick is taken between the two photographs.

## Continuity repair

During this pass, the preceding ABM table's runtime dependency was moved from doc to byte-identical copies under commons, because the project's export filters exclude doc. Its original lesson and behaviour are unchanged. The 40 installed ABM checks were rerun and the earlier report refreshed. This verifies the runtime dependency and behaviour, not a Quest export build.
'''
(O / 'REPORT.md').write_text(report, encoding='utf-8')


def fig(name, caption, eager=False):
    return (f'<figure><a href="assets/{name}.png"><img src="assets/{name}.png" '
            f'alt="{html.escape(caption)}" loading="{"eager" if eager else "lazy"}"></a>'
            f'<figcaption>{html.escape(caption)}</figcaption></figure>')


css = '''*{box-sizing:border-box}body{margin:0;background:#14222c;color:#e7edef;font:17px/1.65 system-ui}nav{display:flex;flex-wrap:wrap;gap:20px;padding:17px 4vw;background:#243542}a{color:#a3dcd9}main{max-width:1460px;margin:auto;padding:36px 26px 70px}h1{font:clamp(44px,7vw,78px)/1.08 Georgia,serif;margin:18px 0;color:#f2d278}h2{font:32px Georgia,serif;margin:36px 0 16px}.eyebrow{text-transform:uppercase;font-size:13px;letter-spacing:.15em;color:#f2d278}p{max-width:980px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:18px}figure{margin:12px 0;background:#243542;padding:10px}img{display:block;width:100%}figcaption{padding:10px;font-size:14px}article{max-width:980px;margin-top:40px}strong{color:#f2d278}@media(max-width:800px){.pair{grid-template-columns:1fr}main{padding:20px 12px}}'''
body = '<p class="eyebrow">Endless Museum / Ant Colony / native Godot captures</p><h1>The channels in hand</h1><p>Stand beside the point. Read its samples. Step its next decision.</p>'
body += fig('returning', 'After FOOD contact: the same sphere carries food. The portable pad now reads HOME and leaves FOOD.', True)
body += '<section id="change"><h2>One point, two roles</h2><p>In ABM the returning point knew home. Here it samples the home channel. Its carrying state chooses which trace to read and which to leave.</p><div class="pair">'
body += fig('search', 'Before stepping: SEARCH. Read FOOD, leave HOME.')
body += fig('returning', 'After one tick: RETURN. Read HOME, leave FOOD.') + '</div></section>'
body += '<section id="hand"><h2>Take the controls with you</h2><p>Grip trigger: run or pause. Buttons: run, one tick, replace points, clear all. Hold an agent to select and move it; release it before stepping. Drop the pad and it returns here after five seconds.</p>'
body += fig('dock', 'The portable pad waits beside the entrance control bank.') + '</section>'
for view, title, explanation in [
    ('above', 'The existing hall', 'The twelve-metre colony and three-size ant comparison remain.'),
    ('field', 'Among the points', 'The original field, spheres and two channels are unchanged.'),
    ('controls', 'The original controls remain', 'Both end controls still operate the same simulation.'),
]:
    body += f'<section id="{view}"><h2>{title}</h2><p>{explanation}</p><div class="pair">'
    body += fig(view + '-before', 'Before — same camera and 260-tick lesson state.') + fig(view + '-after', 'After — ' + explanation) + '</div></section>'
body += '<article id="report">' + markdown.markdown(report, extensions=['extra']) + '</article><p>'
body += ' · '.join(f'<a href="evidence/{name}-checks.json">{name.title()} checks</a>' for name in receipts) + '</p>'
page = '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>The channels in hand — Ant Colony</title><style>' + css + '</style></head><body><nav><a href="#change">Two roles</a><a href="#hand">Hand controls</a><a href="#above">Before &amp; after</a><a href="#report">Report &amp; tests</a><a href="REPORT.md">Editable report</a><a href="../2026-10-11-abm-a-state-in-the-hand/index.html">Previous: ABM</a></nav><main>' + body + '</main></body></html>'
(O / 'index.html').write_text(page, encoding='utf-8')
sources = [Path(__file__), R/'commons/maps'/H/'map_data.json',R/'commons/data/museum/em_plan.json']
sources += list((R/'commons/artifacts/ant_colony_walk').glob('*'))
sources += list((R/'tools/probes').glob('colony_hand_*.gd'))
(O/'evidence/source-hashes.json').write_text(json.dumps({p.relative_to(R).as_posix():sha(p) for p in sources if p.is_file()},indent=2)+'\n',encoding='utf-8')
print(f'Published {total}/{total} checks, {len(preserved)} preserved hashes, nine native images.')
