"""Publish verified native evidence for the Boids appearance comparison."""
from pathlib import Path
import hashlib
import html
import json
import shutil
import markdown

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-11-swarm-three-appearances'
RUN = ROOT / 'ada_run/encounter_pilot/SwarmIntelligence_Boids_Algorithm/swarm-appearance-final'


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


receipts = [
    (ROOT/'ada_run/drone_comparison_checks.json', 'baseline-checks.json'),
    (ROOT/'ada_run/swarm_appearance_checks.json', 'appearance-checks.json'),
    (RUN/'report.json', 'museum-checks.json')]
results = [read(path) for path, _ in receipts]
assert all(r['passed'] and all(c['passed'] for c in r['checks']) for r in results)
logs = [
    (ROOT/'ada_run/drone-appearance-baseline.log', 'baseline.log'),
    (ROOT/'ada_run/swarm-appearance-checks.log', 'appearance.log'),
    (RUN/'stdout.log', 'museum.log')]
for path, _ in logs:
    text = path.read_text(encoding='utf-8')
    assert 'SCRIPT ERROR' not in text and 'SHADER ERROR' not in text, path
preserved = read(OUT/'before/preserved-hashes.json')
changed = [p for p, digest in preserved.items() if sha(ROOT/p) != digest]
assert not changed, changed
for folder in ['assets', 'evidence']:
    (OUT/folder).mkdir(exist_ok=True)
figures = [
    ('drone-view', 'Drone: rotors and a body suggest a machine. Cyan bodies seek separate slots; pink bodies combine neighbour rules with a shared target.'),
    ('point-view', 'Point: the same 24 agents, with their apparatus hidden. Gold still identifies the same witness in each group.'),
    ('light-view', 'Light: an unshaded core and a soft additive halo occupy each body’s position. The room’s lighting has not changed.'),
    ('appearance-control', 'The three-position handle sits beside the carried point. Slide it to change appearance. The point still moves destinations and toggles guides.'),
    ('light-guidance', 'Motion resumes in light mode. The familiar point shifts both destinations; the gold witnesses expose their steering.'),
    ('hall-above', 'Actual Boids hall from above: fish balcony to the west, original exhibits in the middle, comparison court to the east.')]
for name, _ in figures:
    shutil.copy2(RUN/f'{name}.png', OUT/'assets'/f'{name}.png')
for path, name in receipts + logs + [(RUN/'source_manifest.json', 'museum-sources.json')]:
    shutil.copy2(path, OUT/'evidence'/name)
sources = [
    'commons/artifacts/drone_comparison/drone_comparison.gd',
    'commons/artifacts/drone_comparison/drone_comparison.tscn',
    'commons/artifacts/drone_comparison/light_halo.gdshader',
    'commons/artifacts/drone_comparison/README.md',
    'commons/artifacts/registry/drone_comparison.json',
    'tools/probes/drone_comparison_checks.gd',
    'tools/probes/drone_comparison_museum.gd',
    'tools/probes/swarm_appearance_checks.gd',
    'tools/probes/swarm_appearance_museum.gd']
(OUT/'evidence/source-hashes.json').write_text(json.dumps({p:sha(ROOT/p) for p in sources}, indent=2)+'\n', encoding='utf-8')
(OUT/'evidence/preserved-hashes.json').write_text(json.dumps(preserved, indent=2)+'\n', encoding='utf-8')
total = sum(len(r['checks']) for r in results)
report = f'''# One movement, three appearances

Endless Museum · Boids · 11 October 2026

The same moving bodies can appear as drones, points or lights. A physical selector beside the black point changes their appearance while the simulation continues. This adds an art comparison to the existing east court.

## Try it

Reload **Swarm Intelligence → Boids** and enter the east court. Slide the small handle beside the point through **1 Drone / 2 Point / 3 Light**. In VR, grab its handle; on desktop, drag its face with the pointer. Release keeps the choice.

Carry the black point to shift both destination systems. Trigger, or left-click while carrying on desktop, shows or hides the guides. Drop the point and the destinations return to centre. These controls keep their earlier roles.

First watch without guides. Change appearance and follow one gold body. Then restore the guides. Does changing what you see change what you think the group is doing?

## What stays continuous

There are still twelve cyan agents seeking assigned slots and twelve pink agents using neighbours plus a shared destination. Every agent owns three prebuilt visual children. The selector changes visibility; it does not replace an agent, restart its motion or draw a new random number.

The carried point remains the existing PointBody. The view spheres are rendering geometry attached to the moving agents. Gold keeps identifying the same two witnesses. Light mode uses unshaded cores and soft additive halos, without adding a dynamic light to every agent.

This encounter returns to **model and display**. Appearance can suggest a machine, a mathematical point or a field of light. Those readings are questions for the visitor; they are not additional properties proved by the steering code.

## Art connections

Random International’s *Swarm Study / III* makes moving light formations respond to visitors’ movement. It offers a specific comparison for looking at a collective through light and bodily participation. [Artist’s account](https://www.random-international.com/swarm-study-/-iii)

DRIFT describes *Franchise Freedom* in Central Park as a thousand-drone work using algorithms inspired by starling flight. Here, showing and hiding the drone apparatus lets us ask how much the identity of the moving body contributes to the encounter. Our code does not reproduce DRIFT’s algorithm. [Artist’s account](https://studiodrift.com/franchise-freedom-at-new-york-central-park/)

## A short reflection to consider

The rotors disappear. The points keep moving. You turn the handle again and they become lights. Nothing has changed in what each body knows about the others. Something may have changed in what you expect from them.

This is a proposed encounter note. The seven-hall order and all fourteen canonical tutorial/final texts remain unchanged. This optional comparison stays beside the primary Boids lesson. No new room or simulation replaces what was already there.

## Evidence

**{total}/{total} checks passed:** {len(results[0]['checks'])} existing production checks, {len(results[1]['checks'])} appearance checks and {len(results[2]['checks'])} native museum checks.

Two copies received the same moving target over **720 integration steps**. Only one changed appearance, 24 times. Maximum differences in position, velocity and acceleration were **zero**. This verifies that the view switch leaves the tested trajectories intact.

The probes also exercise real pointer events, synthetic XRTools near-grab input under a translated/rotated parent, selector reachability, standing clearance, resumed flight, target movement, guide toggling and release/reset. The original hall checks run again, including its retained flock, aquarium and fish balcony. Logs contain no script or shader errors; existing engine warnings remain in the evidence.

All six images are native Godot captures. For the first three, the probe paused integration to photograph exactly the same agent state from exactly the same camera. It then resumed and checked movement in light mode. The player-facing selector does not pause the simulation.

These are author-operated automated checks. Physical headset use, Quest performance and a fresh independent ghost-student reading remain untested. The agents retain their existing kinematic steering and soft boundaries; their appearance does not add rotor physics or physical collision avoidance.
'''
(OUT/'REPORT.md').write_text(report, encoding='utf-8')
rendered = markdown.markdown(report, extensions=['extra'])
# Native HTML inputs keep the comparison usable under the book-review CSP.
controls = ''.join(f'<input type="radio" name="view" id="view{i}" {"checked" if i==0 else ""}>' for i in range(3))
labels = '<div class="tabs">'+''.join(f'<label for="view{i}">{title}</label>' for i,title in enumerate(['1 · Drone','2 · Point','3 · Light']))+'</div>'
panels = ''.join(f'<figure class="comparison panel{i}"><a href="assets/{name}.png"><img src="assets/{name}.png" alt="{html.escape(caption)}"></a><figcaption>{html.escape(caption)}</figcaption></figure>' for i,(name,caption) in enumerate(figures[:3]))
gallery = ''.join(f'<figure><a href="assets/{name}.png"><img src="assets/{name}.png" loading="lazy" alt="{html.escape(caption)}"></a><figcaption>{html.escape(caption)}</figcaption></figure>' for name,caption in figures[3:])
css = '''*{box-sizing:border-box}body{margin:0;background:#101824;color:#e9e9e5;font:18px/1.65 system-ui}main{max-width:1180px;margin:38px auto;padding:0 24px 70px}h1{font-size:clamp(36px,6vw,66px);line-height:1.08;color:#a8e7ea}h2{margin-top:38px}a{color:#f4accc}nav{padding:16px 24px;background:#202c3e;display:flex;gap:24px;flex-wrap:wrap;font-size:15px}figure{margin:22px 0;background:#202c3e;padding:10px}img{width:100%;height:auto;display:block}figcaption{font-size:15px;padding:10px 5px;color:#d1d9e2}.lede{font-size:21px;max-width:850px}.tabs{display:flex;gap:8px;margin-top:20px}.tabs label{cursor:pointer;padding:10px 22px;border:1px solid #627589;border-radius:4px}.comparison{display:none;margin-top:10px}.switcher input{position:absolute;opacity:0;width:1px;height:1px}#view0:checked~.panel0,#view1:checked~.panel1,#view2:checked~.panel2{display:block}#view0:checked~.tabs label[for=view0],#view1:checked~.tabs label[for=view1],#view2:checked~.tabs label[for=view2]{background:#a8e7ea;color:#101824}input:focus-visible~.tabs{outline:2px solid #f4accc}.note{font-size:14px;color:#b6c6d8}.prose{max-width:880px}'''
body = rendered.replace('<h1>One movement, three appearances</h1>', '', 1)
page = '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>One movement, three appearances — Endless Museum</title><style>'+css+'</style></head><body><nav><a href="#compare">Compare appearances</a><a href="#museum">Museum pictures</a><a href="REPORT.md">Editable report</a><a href="evidence/appearance-checks.json">Motion checks</a><a href="evidence/museum-checks.json">Museum checks</a><a href="../2026-10-10-swarm-complete-readings/index.html">Swarm readings</a></nav><main><h1>One movement,<br>three appearances</h1><p class="lede">Turn the handle. The same bodies become drones, points or lights. Their movement continues.</p><section id="compare" class="switcher">'+controls+labels+panels+'</section><p class="note">Native museum captures. These three photographs hold the agent state and camera fixed for comparison.</p><article class="prose">'+body+'</article><section id="museum"><h2>Inside the museum</h2>'+gallery+'</section></main></body></html>'
(OUT/'index.html').write_text(page, encoding='utf-8')
print(f'Published {total} passing checks, six native images, {len(preserved)} unchanged source hashes.')
