"""Publish native balcony evidence; preserve the prior tutorial review."""
from pathlib import Path
import hashlib
import json
import shutil

R = Path(__file__).resolve().parents[1]
O = R / 'doc/book/iterations/2026-10-10-boids-observation-balcony'
RUN = R / 'ada_run/encounter_pilot/SwarmIntelligence_Boids_Algorithm/balcony'
OLD = R / 'doc/book/iterations/2026-10-10-boids-who-is-near'
(O / 'assets').mkdir(parents=True, exist_ok=True)
receipt = json.loads((RUN / 'report.json').read_text(encoding='utf8'))
assert receipt['passed'] and not receipt['failures']
for stem in ['doorway', 'balcony-eye', 'balcony-look-back', 'above']:
    shutil.copy2(RUN / (stem + '.png'), O / 'assets' / (stem + '.png'))
shutil.copy2(OLD / 'assets/above-after.png', O / 'assets/before.png')
for file in ['report.json', 'source_manifest.json', 'engine.log']:
    shutil.copy2(RUN / file, O / file)
sources = [
    'commons/scenes/em/em_observation_balcony.gd',
    'commons/scenes/endless_museum.gd',
    'commons/maps/SwarmIntelligence_Boids_Algorithm/map_data.json',
    'tools/em_map_halls.py', 'tools/probes/boids_balcony.gd',
]
manifest = {f: hashlib.sha256((R / f).read_bytes()).hexdigest() for f in sources}
(O / 'current-sources.json').write_text(json.dumps(manifest, indent=2), encoding='utf8')
old_plan = json.loads((O / 'before/commons/data/museum/em_plan.json').read_text(encoding='utf8'))
new_plan = json.loads((R / 'commons/data/museum/em_plan.json').read_text(encoding='utf8'))
changed = [b['map'] for a,b in zip(old_plan['plans'],new_plan['plans']) if a != b]
assert changed == ['SwarmIntelligence_Boids_Algorithm']
before_map = json.loads((O / 'before/commons/maps/SwarmIntelligence_Boids_Algorithm/map_data.json').read_text(encoding='utf8'))
after_map = json.loads((R / 'commons/maps/SwarmIntelligence_Boids_Algorithm/map_data.json').read_text(encoding='utf8'))
assert before_map['layers']['interactables'] == after_map['layers']['interactables']
assert before_map['layers']['utilities'] == after_map['layers']['utilities']
summary = '''# Boids — step outside

The large flock already moves beyond the museum walls. A new west balcony gives the visitor somewhere to stand within that wider view. Walk through the three-metre opening beside the flock displays. The eight-by-five-metre deck stays level with the hall; thin dark rails and a pink edge light leave the sky visible. All three exposed edges have collision guards. Turn back through the same doorway to return to the tutorial.

The museum's automatic exterior wall initially sealed the authored opening. The balcony declaration now opens that wall too. The walking probe caught the obstruction before release. The failed first attempt is retained in `investigation/`.

16 native checks pass, including an actual CharacterBody walking out and back with gravity, a continuous floor, clearance through the doorway, all three edge guards and standing sightlines. The photographs come from Godot with the flock running. These checks do not constitute physical headset testing.

The flock's algorithms, counts, materials and movement parameters are unchanged. The tutorial code and reflective text are unchanged. Only the Boids plan row changes; the architecture feature is inactive in halls without a balcony declaration. Reload the Boids hall to build the new architecture. Existing engine UID/render warnings remain outside this change.

Next lesson remains Agent-Based Modeling, the fourth Swarm hall.
'''
(O / 'README.md').write_bytes(summary.encode('utf8'))
css = '''*{box-sizing:border-box}body{margin:0;background:#efeee9;color:#252930;font:19px/1.6 Georgia,serif}header,main{max-width:1200px;margin:auto;padding:28px}header{font:14px system-ui;letter-spacing:.1em;color:#5e5e68}h1{font-size:clamp(42px,6vw,80px);line-height:1.1;margin:12px 0}h2{font-size:30px;margin-top:40px}p{max-width:850px}a{color:#7d3f62}img{display:block;width:100%;height:auto}figure{margin:24px 0}figcaption{font:15px/1.5 system-ui;color:#53545c;margin-top:9px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:24px}.pass{border-left:4px solid #a75b84;background:#e5dde1;padding:18px}nav a{margin-right:20px}@media(max-width:700px){.pair{grid-template-columns:1fr}}'''
html = f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Boids — step outside</title><style>{css}</style><header>ENDLESS MUSEUM / BOIDS / OBSERVATION BALCONY</header><main><h1>Step outside.</h1><p>The flock exceeds the room. Now the visitor has a place to watch it.</p><nav><a href="../2026-10-10-boids-who-is-near/parallel.html">Tutorial and reflection</a><a href="report.json">16 native checks</a><a href="README.md">Change notes</a></nav>
<figure><img src="assets/balcony-eye.png" alt="Standing on the balcony, watching magenta boids and their trails against the starry sky"><figcaption>Actual Godot capture at 1.7 m eye height. The flock keeps moving around and below the balcony.</figcaption></figure>
<p>A level 8 × 5 metre deck extends from the west side of the Boids hall. Enter through the three-metre opening marked <em>Flock Observatory / Step Outside</em>. Thin rails preserve the view; collision guards cover all three exposed sides.</p>
<div class="pair"><figure><img src="assets/doorway.png" alt="The open passage from the museum onto the balcony"><figcaption>Walk straight out of the hall. No jump or separate teleport is needed.</figcaption></figure><figure><img src="assets/balcony-look-back.png" alt="The return route into the museum seen from the balcony"><figcaption>The same opening brings you back to the existing exhibits.</figcaption></figure></div>
<h2>The room and the wider flock</h2><div class="pair"><figure><img src="assets/before.png" alt="Earlier Boids hall without an exterior observation deck"><figcaption>Before: the large flock extends beyond the room, with no exterior viewing floor.</figcaption></figure><figure><img src="assets/above.png" alt="Boids hall from above with the new side balcony"><figcaption>After: the balcony projects into that space. Museum screenshots taken at different moments; this is an architecture comparison.</figcaption></figure></div>
<p class="pass"><strong>16 native checks pass.</strong> A CharacterBody walks out and back with gravity. Floor support, doorway clearance, rail collision and sightlines are checked. Physical headset experience remains untested.</p>
<p>The original 100-boid flock and its movement rules remain. This is a permanent museum addition; the lesson’s printed code is unchanged. Reload the Boids hall to see it.</p></main></html>'''
(O / 'index.html').write_bytes(html.encode('utf8'))
# Link the latest spatial revision from the review the user already has open.
p = OLD / 'index.html'
s = p.read_text(encoding='utf8')
href = '../2026-10-10-boids-observation-balcony/index.html'
if href not in s:
    s = s.replace('</nav>', f'<a href="{href}">New observation balcony</a></nav>', 1)
    p.write_bytes(s.encode('utf8'))
p = R / 'doc/book/course/storyboards/SWARM-HANDOFF.md'
s = p.read_text(encoding='utf8')
if '2026-10-10-boids-observation-balcony' not in s:
    s += '\nBalcony follow-up: permanent 8x5m west deck, map rect[-8,7,8,5], doorway x0,z9..11. Generic opt-in em_observation_balcony architecture, map museum declaration; implicit skin opens too. Thin rails/full collision guards;16 native checks including CharacterBody out/back with gravity and standing sightlines. Physical headset untested. New report doc/book/iterations/2026-10-10-boids-observation-balcony/index.html. Flock, tutorial and final unchanged. All other plan rows unchanged. Reload hall. Next remains ABM.\n'
    p.write_bytes(s.encode('utf8'))
print(f'Published {O / "index.html"}; {len(receipt["checks"])} checks; only Boids placement row changed.')
