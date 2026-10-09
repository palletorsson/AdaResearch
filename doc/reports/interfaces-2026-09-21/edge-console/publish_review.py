"""Publish real artifact captures, variant evidence and the regression record."""
from pathlib import Path
import difflib
import hashlib
import json
import re
import shutil

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
DEST = ROOT/'doc/book/iterations/2026-09-21-interface-edge-console-review'
PREVIOUS = ROOT/'doc/book/iterations/2026-09-21-interface-fitness-console-review/index.html'
checks = json.loads((HERE/'checks.json').read_text())
regressions = json.loads((HERE/'regressions.json').read_text())
assert not checks['failures'] and all(not x['failures'] for x in regressions.values())
total = checks['checks'] + sum(x['checks'] for x in regressions.values())
DEST.mkdir(parents=True, exist_ok=True)
for path in HERE.glob('*.png'):
    shutil.copy2(path, DEST/path.name)
for name in ['checks.json', 'regressions.json']:
    shutil.copy2(HERE/name, DEST/name)
shutil.copy2(HERE/'README.md', DEST/'implementation.md')
sources = ['commons/artifacts/edge_of_chaos_unlocked/edge_of_chaos_unlocked.gd',
           'commons/ui/physical_parameter_console.gd', 'commons/interactables/physical_stepped_slider.gd',
           'commons/testing/test_edge_physical_console.gd']
hashes = {path: hashlib.sha256((ROOT/path).read_bytes()).hexdigest() for path in sources}
for folder in [HERE, DEST]:
    (folder/'source-hashes.json').write_text(json.dumps(hashes, indent=2))
diff = ''.join(difflib.unified_diff(
    (HERE/'before/edge_of_chaos_unlocked.gd.txt').read_text(encoding='utf-8').splitlines(True),
    (ROOT/sources[0]).read_text(encoding='utf-8').splitlines(True), fromfile='before/'+sources[0], tofile='after/'+sources[0]))
(HERE/'artifact.diff').write_text(diff, encoding='utf-8')
previous = PREVIOUS.read_text(encoding='utf-8')
css = re.search(r'<style>(.*?)</style>', previous, re.S).group(1)
css += '\n.variants{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:16px}.variants figure{margin:0}@media(max-width:850px){.variants{grid-template-columns:1fr}}'
page = f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Who can move the handle? · Ada Research</title><style>{css}</style></head>
<body><header><div class="eyebrow">Ada Research · Physical interface pass · 21 September 2026</div>
<h1>Who can move<br>the handle?</h1>
<p class="lead">A physical console for the edge-of-chaos experiment. The controls sit together in front of the fields, while access to lambda remains part of the work.</p>
<p><a href="../2026-09-21-interface-fitness-console-review/index.html">Previous: the fitness console</a> · <a href="/necklace/thread?map=QFEP_Edge_Of_Chaos&amp;role=primary">The hall and its book text</a></p>
<div class="metrics"><div class="metric"><strong>2 rails</strong><span>Continuous lambda · Eight speed stops</span></div><div class="metric"><strong>5 access states</strong><span>Checked in single and paired versions</span></div><div class="metric"><strong>{total} checks</strong><span>Edge, grammar and fitness pass</span></div></div></header>
<main><section><h2>Physical controls, flat text</h2>
<figure class="hero-image"><a href="after-close.png"><img src="after-close.png" width="1600" height="1200" alt="Two physical faders beside four raised buttons, with a live readout seated in the same inclined console"></a><figcaption>The paired experiment: lambda, speed, restart, new seed, timestep and hold. The readout reports the actual calculation.</figcaption></figure>
<p>Lambda changes one authored route through the reaction-diffusion coefficients. Speed controls how quickly model time is requested. The timestep button restarts the same seed with a finer calculation. These are different operations, now gathered within one backed surface.</p></section>
<section><h2>See the consequence above the controls</h2>
<div class="comparison"><figure><a href="before-front.png"><img src="before-front.png" width="1600" height="1200" alt="Before: the paired experiment with separate control assemblies"></a><figcaption>Before: controls split across assemblies.</figcaption></figure><figure><a href="after-front.png"><img src="after-front.png" width="1600" height="1200" alt="After: two fields visible above one grouped console"></a><figcaption>After: one front console below the two fields.</figcaption></figure></div>
<p>Both captures use the same camera, seed, lambda and model time. The two fields and their timestep labels stay visible from this operating pose. The simulation results match the previous implementation exactly after 200 ticks.</p></section>
<section><h2>Available, held, absent</h2><div class="variants">
<figure><a href="unlocked-close.png"><img src="unlocked-close.png" width="1600" height="1200" alt="Unlocked: both physical faders are available"></a><figcaption><strong>Unlocked.</strong> The lambda handle responds to grabbing or pointer dragging.</figcaption></figure>
<figure><a href="clamped-close.png"><img src="clamped-close.png" width="1600" height="1200" alt="Clamped: a bolted metal bar holds the lambda cap"></a><figcaption><strong>Clamped.</strong> A bar holds the cap, and input cannot move it.</figcaption></figure>
<figure><a href="withheld-close.png"><img src="withheld-close.png" width="1600" height="1200" alt="Withheld: a riveted plate labelled lambda not fitted replaces the fader"></a><figcaption><strong>Withheld.</strong> There is no hidden lambda control behind the blank.</figcaption></figure></div>
<p>The low and high preset versions also hold lambda. Speed, restart and seed controls stay available. These access rules apply to both the single field and paired experiment.</p>
<p>The single-field clamped version keeps its deliberately contradictory UNLOCKED sign. Better controls should help the visitor encounter that contradiction. The withheld version retains its changed title and identifies the missing fader directly on the console.</p></section>
<section><h2>State follows the hand—and the source</h2>
<p>Previously a locked handle could move while its value was ignored. It now refuses both grab and pointer input. External configuration still sets the parameter when authorized by the map, and the held cap and bracket follow that value together.</p>
<p>HOLD and the smaller timestep have persistent selected-button feedback. RESTART repeats the numbered seed; NEW SEED changes it. The difference between the two B fields remains visible without calling that number a measure of beauty, life or chaos.</p></section>
<section><h2>A reusable parameter station</h2>
<p>The shared component accepts two parameter definitions and up to four actions. Each parameter declares whether it is available, held or absent. The same physical-slider implementation now supports continuous values, discrete stops and authored input restrictions.</p>
<p><a href="checks.json">{checks['checks']} edge checks</a> exercise XR grab-driver movement, physics ray input, all ten access/comparison combinations, readout synchronization, pause, seed and timestep controls, and live reconfiguration. <a href="regressions.json">{regressions['grammar']['checks']} grammar and {regressions['fitness']['checks']} fitness checks</a> protect the earlier controls.</p></section>
<section><h2>What still needs the museum</h2>
<p>These are real Godot artifact captures in a desktop test scene. Headset reach, tracked-hand comfort, placement on raised exhibit furniture and standalone Quest performance remain untested. The next useful pass is to check the shared consoles inside their actual halls before widening the migration.</p>
<p><a href="implementation.md">Implementation, reuse and capture details</a> · <a href="source-hashes.json">Source hashes</a></p></section></main>
<footer>Physical controls · Flat surface text · Access is part of the encounter</footer></body></html>'''
(DEST/'index.html').write_text(page, encoding='utf-8')
link = '<p><a href="../2026-09-21-interface-edge-console-review/index.html">Continue: who can move the handle?</a></p>'
if link not in previous:
    PREVIOUS.write_text(previous.replace('<footer>', '<footer>'+link), encoding='utf-8')
print(DEST/'index.html')
