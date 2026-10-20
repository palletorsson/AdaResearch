"""Publish evidence from the production fish-school checks and native museum run."""
from pathlib import Path
import hashlib
import html
import json
import shutil

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-10-fish-a-point-they-can-sense'
RUN=ROOT/'ada_run/encounter_pilot/SwarmIntelligence_Boids_Algorithm/fish-school'
OUT.mkdir(parents=True,exist_ok=True)
(OUT/'assets').mkdir(exist_ok=True)
(OUT/'evidence').mkdir(exist_ok=True)
unit=json.loads((ROOT/'ada_run/fish_school_checks.json').read_text())
native=json.loads((RUN/'report.json').read_text())
assert unit['passed'] and native['passed']
for log in [ROOT/'ada_run/fish_school_stdout.log',RUN/'stdout.log']:
    assert 'SCRIPT ERROR' not in log.read_text(encoding='utf8'),log
for name in ['balcony-school','gather','scatter','school-above']:
    shutil.copy2(RUN/f'{name}.png',OUT/'assets'/f'{name}.png')
shutil.copy2(ROOT/'ada_run/fish_school_checks.json',OUT/'evidence/code-checks.json')
shutil.copy2(RUN/'report.json',OUT/'evidence/museum-checks.json')
shutil.copy2(RUN/'source_manifest.json',OUT/'evidence/museum-sources.json')
old=json.loads((ROOT/'doc/book/iterations/2026-10-10-swarms-fish-drones-and-hordes/scope.json').read_text())
assert all(hashlib.sha256((ROOT/p).read_bytes()).hexdigest()==h for p,h in old['source_texts_sha256'].items())
sources=[
 'algorithms/emergentsystems/boidflocking/Boid.gd',
 'commons/artifacts/fish_school/fish_school.gd','commons/artifacts/fish_school/fish.gd',
 'commons/artifacts/fish_school/fish_school.tscn','commons/artifacts/registry/fish_school.json',
 'commons/artifacts/particle_swarm_walk/point_body.gd',
 'commons/maps/SwarmIntelligence_Boids_Algorithm/map_data.json','commons/data/museum/em_plan.json',
 'tools/probes/fish_school_checks.gd','tools/probes/fish_school_museum.gd']
(OUT/'evidence/source-hashes.json').write_text(json.dumps({p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in sources},indent=2)+'\n')
n=len(unit['checks'])+len(native['checks'])
obs=native['observations']
summary=f'''# A school within reach

Built in the Endless Museum · 10 October 2026

There are now 72 fish beside the Boids hall's observation balcony. Pick up the black point from its stand: nearby fish gather. Hold the trigger to scatter them. Release the trigger and they gather again. Let go of the point and the school continues through its own neighbour rules. The point returns to its stand after 1.5 seconds.

## Try it

Reload **Swarm Intelligence → Boids Algorithm** and walk through the west opening onto the balcony. The point is on a pale stand, 1.18 m above the deck.

- **VR:** grip to carry; hold trigger to scatter; release grip to leave it.
- **Desktop:** right-click to carry/drop; hold left-click to scatter; move the mouse to guide the carried point.
- **Look:** cyan means gather, pink means scatter. The large rings mark the eight-metre range. The gold-ringed fish carries an arrow showing the sphere's steering contribution.

## What carries forward

The point is the existing PointBody class. The new fish reuse the original Boid steering code: separation, alignment and cohesion. This encounter adds an explicit fourth contribution, desired velocity minus current velocity, limited by strength and distance. Aiming for the point and fleeing it become changes in the same calculation. The boundary also contributes a turn, so the hand never has sole control.

This makes a useful optional bridge from the tested neighbour lesson to seek/flee steering. The fish are stylized agents; their shape does not establish biological accuracy. [The Nature of Code: autonomous agents](https://natureofcode.com/autonomous-agents/) supplies the relevant steering framework.

The original 100-prism flock, one-metre aquarium, controls and balcony remain. The 72 fish are a new companion encounter, not the original flock reskinned. The fourteen canonical tutorial/final files and the sequence order match their pre-change hashes.

## Evidence

**{n}/{n} checks passed:** {len(unit['checks'])} focused production-code checks and {len(native['checks'])} native museum checks, including four retained-camera captures.

The tests cover real integration, transformed coordinates, radius and strength limits, coincident positions, action/release, return to the stand, finite motion and capped speed over 20 simulated seconds, and the original Boid defaults. In the actual hall, a standing capsule has a clear approach and the stand is reachable. Only the stand seals navigation cells; the fish and visible range rings do not.

In this native run, mean distance from the point was **{obs['mean_distance_gather']:.2f} m after gathering**, then **{obs['mean_distance_scatter']:.2f} m after three seconds of scattering**. These are observations from this run, not universal target distances. The simulation kept running during the images.

Pickup and trigger events were supplied by the probe. Physical headset use and Quest performance remain untested. The native run has an existing unresolved UID warning; no script errors were logged. All pictures below are captures from Godot in the actual museum.
'''
(OUT/'REPORT.md').write_text(summary,encoding='utf8')
import markdown
body=markdown.markdown(summary,extensions=['extra'])
figures=''.join(f'<figure><a href="assets/{name}.png"><img src="assets/{name}.png" alt="{html.escape(caption)}" loading="lazy"></a><figcaption>{html.escape(caption)}</figcaption></figure>' for name,caption in [
 ('balcony-school','The new school on the existing balcony.'),('gather','Hold the same point: a local attraction joins the neighbour rules.'),('scatter','Trigger held: the hand contribution turns outward. The gold-ringed fish shows its steering arrow.'),('school-above','The actual room from above: aquarium and controls inside, fish encounter beside the balcony.')])
css='''*{box-sizing:border-box}body{margin:0;background:#101e2c;color:#e4e8e7;font:18px/1.65 system-ui}main{max-width:1150px;margin:40px auto;padding:0 24px 70px}h1{font-size:clamp(36px,5vw,64px);line-height:1.08;color:#8be2e4}h2{margin-top:42px}a{color:#91e1e8}nav{padding:16px 24px;background:#1a3043;display:flex;gap:25px;flex-wrap:wrap}figure{margin:24px 0;background:#1b3040;padding:12px}img{width:100%;height:auto;display:block}figcaption{padding:12px 6px;font-size:15px;color:#bdcbd1}strong{color:#fff}li{margin:7px 0}.gallery{margin-top:45px}'''
(OUT/'index.html').write_text('<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>A school within reach</title><style>'+css+'</style></head><body><nav><a href="#pictures">Museum pictures</a><a href="REPORT.md">Editable report</a><a href="evidence/museum-checks.json">Museum checks</a><a href="evidence/code-checks.json">Code checks</a><a href="../2026-10-10-swarm-complete-readings/index.html">Swarm readings</a></nav><main>'+body+'<section id="pictures" class="gallery">'+figures+'</section></main></body></html>',encoding='utf8')
print(f'Published fish-school report: {n} passing checks, 4 native images; canonical readings unchanged.')
