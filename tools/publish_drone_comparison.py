"""Publish native evidence for the optional Boids drone comparison."""
from pathlib import Path
import hashlib
import html
import json
import shutil
import markdown

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-11-drones-two-kinds-of-guidance'
HALL = 'SwarmIntelligence_Boids_Algorithm'
RUN = ROOT / f'ada_run/encounter_pilot/{HALL}/drone-comparison-final'


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


code = read(ROOT/'ada_run/drone_comparison_checks.json')
native = read(RUN/'report.json')
assert code['passed'] and native['passed']
for log in [ROOT/'ada_run/drone-comparison-checks.log', RUN/'stdout.log']:
    assert 'SCRIPT ERROR' not in log.read_text(encoding='utf-8'), log
preserved = read(OUT/'before/preserved-hashes.json')
assert all(sha(ROOT/p) == digest for p, digest in preserved.items())
old = read(OUT/'before/em_plan.json')
new = read(ROOT/'commons/data/museum/em_plan.json')
assert [r for r in old['plans'] if r.get('map') != HALL] == [r for r in new['plans'] if r.get('map') != HALL]
assert {k:v for k,v in old.items() if k != 'plans'} == {k:v for k,v in new.items() if k != 'plans'}
for folder in ['assets', 'evidence']:
    (OUT/folder).mkdir(exist_ok=True)
figures = [
    ('two-flights', 'From the aisle: twelve cyan drones seek assigned slots; twelve pink drones share a destination and use neighbour rules.'),
    ('hand-guidance', 'Moving the point changes both destination systems. The gold witnesses expose their steering; thin links show destinations and nearby bodies.'),
    ('without-guides', 'The same two flights with guidance hidden. Trigger changes the display, not the movement rules.'),
    ('point-control', 'The familiar black PointBody is the hand control. Carry it to move destinations; trigger toggles guidance; release returns it to the stand.'),
    ('hall-above', 'Actual hall from above: the original Boids exhibits remain in the middle, the fish balcony is west, and the comparison court is east.')]
for name, _ in figures:
    shutil.copy2(RUN/f'{name}.png', OUT/'assets'/f'{name}.png')
for source, name in [
    (ROOT/'ada_run/drone_comparison_checks.json', 'code-checks.json'),
    (ROOT/'ada_run/drone-comparison-checks.log', 'code.log'),
    (RUN/'report.json', 'museum-checks.json'),
    (RUN/'stdout.log', 'museum.log'),
    (RUN/'source_manifest.json', 'museum-sources.json')]:
    shutil.copy2(source, OUT/'evidence'/name)
sources = [
    'commons/artifacts/drone_comparison/drone.gd',
    'commons/artifacts/drone_comparison/flight.gd',
    'commons/artifacts/drone_comparison/drone_comparison.gd',
    'commons/artifacts/drone_comparison/drone_comparison.tscn',
    'commons/artifacts/registry/drone_comparison.json',
    'algorithms/emergentsystems/boidflocking/Boid.gd',
    'commons/artifacts/particle_swarm_walk/point_body.gd',
    f'commons/maps/{HALL}/map_data.json', 'commons/data/museum/em_plan.json',
    'tools/probes/drone_comparison_checks.gd', 'tools/probes/drone_comparison_museum.gd']
(OUT/'evidence/source-hashes.json').write_text(json.dumps({p:sha(ROOT/p) for p in sources}, indent=2)+'\n')
total = len(code['checks']) + len(native['checks'])
report = f'''# Two kinds of guidance

Endless Museum · Boids · 11 October 2026

Two flights begin alike. Move the black point. The cyan bodies recover assigned places; the pink bodies adjust to neighbours while seeking a shared destination. Similar-looking groups can be held together by different instructions.

## Try it in the museum

Reload **Swarm Intelligence → Boids** and enter the new east court through the opening in the existing room. The black point waits on a pale stand at hand height. A 2.2 m aisle runs between the flights.

- **VR:** grip and carry the point. Trigger shows or hides guidance.
- **Desktop:** right-click to carry/drop; left-click while carrying toggles guidance.
- Move it left, right, up or down. Both destination systems receive the same bounded displacement.
- Let go. The targets ease back to centre; the point returns to its stand after 1.5 seconds.

## What changes between the flights

| Kept in both | Cyan: assigned slots | Pink: neighbours + common target |
| --- | --- | --- |
| Twelve agents, identical relative starts and velocities | One destination per body | One shared destination |
| Same separation, arrival rule, speed cap and boundary rule | Alignment and cohesion off | Alignment and cohesion on |
| Same carried point | Moves the whole slot arrangement | Moves the common target |

The gold drone in each flight is a stable witness. Its gold arrow shows actual total acceleration at **0.25 m per m/s²**. A fine link leads to its destination. Pink links connect the witness to bodies within its two-metre perception radius. At rest, an acceleration arrow can shrink away. Trigger removes these guides without changing the simulation.

The drone bodies reuse the existing museum Boid movement code. Their new adapter supplies an arrival request. The hand control reuses the existing PointBody. The two groups read their own neighbours, so they do not steer toward the other flight across the aisle.

## What this adds to the sequence

Fish made the point a source of attraction or repulsion. The listening crowd kept a position after the point moved away. Here the point changes a destination, and the comparison makes the source of coordination visible. The new question is **which information each body uses**.

This is an optional encounter beside the primary Boids lesson. The fourteen canonical tutorial/final texts and seven-hall order are unchanged. The original flock, aquarium, controls and fish balcony remain. The map extends from 13 × 13 to 28 × 13 cells; its automatic entry partition is disabled because it otherwise cuts through the new comparison court. Authored walls and existing exhibit placements remain, apart from the three-cell opening to the court.

## A possible reflection

You move one point; two groups answer. One carries twelve appointed places. The other keeps measuring who is near. The order you see does not tell you how it was made. Both movements depend on choices we have written into the room. Show their guides and some of those choices become visible.

This is an encounter note, not an insertion into the agreed final text.

## Evidence and limits

**{total}/{total} checks passed:** {len(code['checks'])} production-code checks and {len(native['checks'])} native museum checks, including five rendered captures.

The code checks exercise the real Boid integrator, matching initial conditions, separate neighbourhoods, destination semantics, arrival braking, synthetic pickup/action, transformed coordinates, display-only toggling, finite and speed-capped movement, formation convergence and extreme hand targets. Forty seconds at neutral plus fifteen seconds at each extreme remain bounded in the tested setup.

The museum checks exercise the real hall, standing-capsule clearance and floor support through the opening and aisle, point reachability, live target movement, guide visibility, release/reset and retained exhibits. All images are native Godot captures. The final run has no script errors; the existing unresolved UID warning remains in its log.

An early capture exposed the unwanted partition. The first control checks also sampled from the overhead camera and before the display had updated; the final probe returns to visitor height and waits for the update. Failed receipts are retained in the earlier run folders.

These are kinematic agents with soft steering and separation. Rotor dynamics, sensor noise, physical collisions and real-drone flight control are not simulated. Both flights contain authored goals and constraints. The neighbour-driven flight is not a demonstration of complete decentralization. The production Boid integrator reads sequential live states, unlike the snapshot update used in the printed tutorial model.

Physical headset use, portal crossing and Quest performance remain untested. This encounter run is not a new ghost-student assessment of the book.
'''
(OUT/'REPORT.md').write_text(report, encoding='utf-8')
body = markdown.markdown(report, extensions=['extra'])
gallery = ''.join(f'<figure><a href="assets/{name}.png"><img src="assets/{name}.png" loading="lazy" alt="{html.escape(caption)}"></a><figcaption>{html.escape(caption)}</figcaption></figure>' for name, caption in figures)
css = '*{box-sizing:border-box}body{margin:0;background:#111b29;color:#e9e8e4;font:18px/1.65 system-ui}main{max-width:1150px;margin:42px auto;padding:0 24px 70px}h1{font-size:clamp(38px,6vw,68px);line-height:1.08;color:#84dce7}h2{margin-top:44px}a{color:#f59bbd}nav{padding:16px 24px;background:#233043;display:flex;gap:24px;flex-wrap:wrap}figure{margin:26px 0;background:#243143;padding:12px}img{width:100%;height:auto;display:block}figcaption{padding:12px 6px;font-size:15px;color:#ccd4dd}li{margin:8px 0}table{border-collapse:collapse;width:100%;font-size:16px}td,th{padding:12px;border:1px solid #455569;text-align:left}'
hero = '<figure><img src="assets/two-flights.png" alt="The two drone flights in the actual Boids museum hall"><figcaption>Native museum capture. Carry the same point; compare two kinds of guidance.</figcaption></figure>'
(OUT/'index.html').write_text('<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Two kinds of guidance — Endless Museum</title><style>'+css+'</style></head><body><nav><a href="#pictures">Museum pictures</a><a href="REPORT.md">Editable report</a><a href="evidence/code-checks.json">Code checks</a><a href="evidence/museum-checks.json">Museum checks</a><a href="../2026-10-10-swarm-complete-readings/index.html">Swarm readings</a></nav><main>'+hero+body+'<section id="pictures"><h2>Inside the museum</h2>'+gallery+'</section></main></body></html>', encoding='utf-8')
print(f'Published drone comparison: {total} passing checks, five native images; readings/order and other plan rows unchanged.')
