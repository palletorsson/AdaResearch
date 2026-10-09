"""Publish actual Godot evidence for the reusable physical choice console."""
from pathlib import Path
import difflib
import hashlib
import json
import re
import shutil

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
DEST = ROOT/'doc/book/iterations/2026-09-21-interface-fitness-console-review'
PREVIOUS = ROOT/'doc/book/iterations/2026-09-21-interface-physical-slider-review/index.html'
checks = json.loads((HERE/'checks.json').read_text())
regressions = json.loads((HERE/'regressions.json').read_text())
assert not checks['failures'] and all(not result['failures'] for result in regressions.values())
total = checks['checks'] + sum(result['checks'] for result in regressions.values())
DEST.mkdir(parents=True, exist_ok=True)
for name in ['before-front.png', 'before-overview.png', 'after-front.png', 'after-close.png', 'after-overview.png', 'ridge-overview.png', 'checks.json', 'regressions.json']:
    shutil.copy2(HERE/name, DEST/name)
shutil.copy2(HERE/'README.md', DEST/'implementation.md')
sources = ['commons/ui/physical_choice_console.gd',
           'commons/interactables/physical_stepped_slider.gd',
           'commons/interactables/push_button.gd',
           'commons/interactables/interactable_area_button_pointer.gd',
           'commons/artifacts/fitness_landscape_politics/fitness_landscape_politics.gd',
           'commons/testing/test_fitness_physical_console.gd']
hashes = {path: hashlib.sha256((ROOT/path).read_bytes()).hexdigest() for path in sources}
for folder in [HERE, DEST]:
    (folder/'source-hashes.json').write_text(json.dumps(hashes, indent=2))
path = sources[-2]
diff = ''.join(difflib.unified_diff(
    (HERE/'before/fitness_landscape_politics.gd.txt').read_text(encoding='utf-8').splitlines(True),
    (ROOT/path).read_text(encoding='utf-8').splitlines(True), fromfile='before/'+path, tofile='after/'+path))
(HERE/'artifact.diff').write_text(diff, encoding='utf-8')
previous = PREVIOUS.read_text(encoding='utf-8')
css = re.search(r'<style>(.*?)</style>', previous, re.S).group(1)
page = f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>A choice you can see · Ada Research</title><style>{css}</style></head>
<body><header><div class="eyebrow">Ada Research · Physical interface pass · 21 September 2026</div>
<h1>A choice<br>you can see.</h1>
<p class="lead">Change what the swarm rewards. Four physical buttons, one continuous fader, and a selected rule that remains visible after your hand leaves.</p>
<p><a href="../2026-09-21-interface-physical-slider-review/index.html">Previous: the grammar handle</a> · <a href="/necklace/thread?map=SwarmIntelligence_Particle_Swarm_Optimization&amp;role=primary">Particle-swarm hall</a></p>
<div class="metrics"><div class="metric"><strong>4 choices</strong><span>One visibly selected rule</span></div><div class="metric"><strong>0–1</strong><span>Continuous inertia, held after release</span></div><div class="metric"><strong>{total} checks</strong><span>Fitness, grammar and Shannon pass</span></div></div></header>
<main><section><h2>Something to press. Something to hold.</h2>
<figure class="hero-image"><a href="after-close.png"><img src="after-close.png" width="1600" height="1200" alt="Inclined console with four raised buttons, a physical inertia fader, reset button and flat printed labels"></a><figcaption>The current Godot artifact. The green cap marks the selected reward. The fader moves continuously; the numbered marks do not impose discrete stops.</figcaption></figure>
<p>The interface is a compact physical object. Buttons move into their backing when touched; the fader can be grabbed or dragged with a pointer. Titles, numbers and captions stay flat on surfaces. RESET restores the starting population while keeping the chosen reward and inertia.</p></section>
<section><h2>From a side column to a front station</h2><div class="comparison">
<figure><a href="before-overview.png"><img src="before-overview.png" width="1600" height="1200" alt="Before: a vertical control column stands beside the terrain"></a><figcaption>Before: controls beside the work.</figcaption></figure>
<figure><a href="after-overview.png"><img src="after-overview.png" width="1600" height="1200" alt="After: the grouped physical console stands in front of the same terrain"></a><figcaption>After: player → controls → terrain, with a supported caption behind.</figcaption></figure></div>
<p>These views use the same camera and initial simulation. The seeded agents and terrain colours are unchanged. All four reward functions are now accessible in the default placement; previously RIDGE was only available in a configured variant.</p></section>
<section><h2>At the operating position</h2>
<figure><a href="after-front.png"><img src="after-front.png" width="1600" height="1200" alt="Standing view over the low console towards the swarm and caption"></a><figcaption>A desktop camera at local height 1.65 m. The lower panel exposes more of the terrain, although part of its near edge remains covered. <a href="before-front.png">Same position before.</a></figcaption></figure>
<p>The panel follows the terrain size and sits on a narrow stand. This is a test-scene view of the actual artifact; it is not a headset or full-hall capture. Reach and placement on raised furniture need a separate check in the museum.</p></section>
<section><h2>The same agents, another reward</h2>
<figure><a href="ridge-overview.png"><img src="ridge-overview.png" width="1600" height="1200" alt="The ridge reward creates a bright diagonal scoring band and the swarm gathers near it"></a><figcaption>RIDGE selected, after 120 simulation steps. The terrain, selected cap and caption agree.</figcaption></figure>
<p>The rule changes immediately; the swarm responds over time. Its mathematical behaviour is preserved. The interface makes the choice and its persistence easier to notice.</p></section>
<section><h2>A pattern other artifacts can use</h2>
<p>The shared choice console combines up to four physical choices, one continuous parameter and reset. Its owner controls the selection and readout, so configuration changes and direct interaction tell the same story. It reuses the existing physical buttons and the grammar fader, with an explicit continuous mode.</p>
<p>Shared repairs also ensure that untouched buttons display their configured colour and that a disappearing pointer cannot leave a cap pressed. A hand still touching the button retains its own press.</p></section>
<section><h2>Evidence and the next step</h2>
<p><a href="checks.json">{checks['checks']} fitness checks</a> exercise physics touch, ray hits, cap travel, XR Tools grab and release, state updates and reset. <a href="regressions.json">{regressions['grammar']['checks']} grammar and {regressions['shannon']['checks']} Shannon checks</a> protect the earlier shared-control work.</p>
<p>Headset comfort, tracked-hand behaviour and Quest performance remain untested. Next is the edge-of-chaos interface, where different configurations deliberately grant or withhold control. Improving its presentation must preserve that distinction.</p>
<p><a href="implementation.md">Implementation, reuse and limits</a> · <a href="source-hashes.json">Source hashes</a></p></section></main>
<footer>Physical controls · Flat surface text · Headset test pending</footer></body></html>'''
(DEST/'index.html').write_text(page, encoding='utf-8')
link = '<p><a href="../2026-09-21-interface-fitness-console-review/index.html">Continue: physical choices in front of the fitness landscape.</a></p>'
if link not in previous:
    PREVIOUS.write_text(previous.replace('<footer>', '<footer>'+link), encoding='utf-8')
print(DEST/'index.html')
