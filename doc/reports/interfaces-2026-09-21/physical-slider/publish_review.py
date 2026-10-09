"""Publish matched Godot captures of the physical and preserved screen controls."""
from pathlib import Path
import hashlib
import json
import re
import shutil

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
DEST = ROOT/'doc/book/iterations/2026-09-21-interface-physical-slider-review'
PREVIOUS = ROOT/'doc/book/iterations/2026-09-20-interface-rack-wrapper-review/index.html'
physical = json.loads((HERE/'checks.json').read_text(encoding='utf-8'))
screen = json.loads((HERE/'screen-regression/checks.json').read_text(encoding='utf-8'))
assert not physical['failures'] and not screen['failures']
DEST.mkdir(parents=True, exist_ok=True)
for name in ['physical-close.png', 'physical-front.png', 'screen-close.png', 'screen-front.png', 'checks.json']:
    shutil.copy2(HERE/name, DEST/name)
shutil.copy2(HERE/'screen-regression/checks.json', DEST/'screen-checks.json')
shutil.copy2(HERE/'README.md', DEST/'implementation.md')
sources = ['commons/interactables/physical_stepped_slider.gd',
           'commons/interactables/artifact_controls.gd',
           'commons/artifacts/grammar_provenance/grammar_provenance.gd',
           'commons/testing/test_physical_stepped_slider.gd',
           'commons/testing/test_rack_wrapper_input.gd']
hashes = {path: hashlib.sha256((ROOT/path).read_bytes()).hexdigest() for path in sources}
for folder in [HERE, DEST]:
    (folder/'source-hashes.json').write_text(json.dumps(hashes, indent=2), encoding='utf-8')
previous = PREVIOUS.read_text(encoding='utf-8')
css = re.search(r'<style>(.*?)</style>', previous, re.S).group(1)
css += '\n.comparison{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:20px}.comparison figure{margin:0}.comparison img{width:100%;height:auto} @media(max-width:760px){.comparison{grid-template-columns:1fr}}'
page = f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>A handle you can hold · Ada Research</title><style>{css}</style></head>
<body><header><div class="eyebrow">Ada Research · Physical interface pilot · 21 September 2026</div>
<h1>A handle<br>you can hold.</h1>
<p class="lead">The grammar station now has a moving 3D slider. Its title, numbers and depth readout remain flat on surfaces. The interface stays in front of the work.</p>
<p><a href="../2026-09-20-interface-rack-wrapper-review/index.html?placement=front">Previous screen version</a> · <a href="/necklace/thread?map=LSystems_Grammar_Lab&amp;role=primary">Grammar hall</a></p>
<div class="metrics"><div class="metric"><strong>6 stops</strong><span>A graspable handle along an 18 cm track</span></div><div class="metric"><strong>Grab + pointer</strong><span>Both operate the same retained selection</span></div><div class="metric"><strong>{physical['checks']} + {screen['checks']}</strong><span>Physical checks and retained-screen regressions pass</span></div></div></header>
<main><section><h2>Physical movement, flat lettering</h2>
<figure class="hero-image"><a href="physical-close.png"><img src="physical-close.png" width="1600" height="1200" alt="The physical depth slider with a raised dark grip, orange index and six printed positions, above a flat Depth 2 readout"></a><figcaption>Actual Godot rendering. The cap projects from the face and moves through six positions. The selected depth remains after release.</figcaption></figure>
<p>“2D in 3D” describes the text. The controls can have depth, movement and graspable parts. Here the numbered scale is printed on the face; the grip is a 3D object constrained to its track.</p></section>
<section><h2>The same station, two ways to operate it</h2>
<div class="comparison"><figure><a href="physical-close.png"><img src="physical-close.png" width="1600" height="1200" alt="Physical slider at generation two"></a><figcaption><strong>Physical: current default.</strong> Near grab or pointer drag moves the handle.</figcaption></figure><figure><a href="screen-close.png"><img src="screen-close.png" width="1600" height="1200" alt="Preserved flat screen slider at generation two"></a><figcaption><strong>Screen: retained comparison.</strong> Pointer input operates the drawn slider.</figcaption></figure></div>
<p>Both captures use generation two and exactly the same camera pose. The supporting case, inclination and depth display keep their previous visual size. Physics nodes stay at unit scale in the physical assembly.</p></section>
<section><h2>Player → controls → work</h2>
<figure><a href="physical-front.png"><img src="physical-front.png" width="1600" height="1200" alt="Operating-position view with the physical slider in front and all three grammar forms and provenance panels visible behind it"></a><figcaption>Standing test view at local height 1.65 m. The forms and all three provenance boards remain visible behind the controls. <a href="screen-front.png">Compare the screen version from the same position.</a></figcaption></figure>
<p>The captures instantiate the real artifact in a test scene. They establish its assembly and sightline at this pose; they are not museum-hall or headset captures.</p></section>
<section><h2>From a moving hand to a changed form</h2>
<p>The test moves a generated grabber through the actual XR Tools pickup, grab-driver and release path. It visits all six stops in both directions and holds each still. Separate physics rays exercise pointer dragging, competing pointers, exit and focus loss.</p>
<p>In the real grammar artifact, both grab and pointer input change generation one to two: the first grammar goes from five to twenty-five rendered segments, and its readout changes to Depth: 2. The tests also found and fixed a feedback bug where a stationary held proxy could repeatedly advance its parent track.</p>
<p><a href="checks.json">{physical['checks']} physical checks</a> and <a href="screen-checks.json">{screen['checks']} retained-screen checks</a> pass. The complete selector range is checked on the isolated control; the real geometry check uses generations one and two. The existing much heavier generation-six rendering has not been performance-certified.</p></section>
<section><h2>What this establishes</h2>
<p>One artifact now uses a physical control through a reusable helper. The grammar rules and manuscript are unchanged. The screen variant remains available for comparison; other artifact interfaces retain their existing implementations.</p>
<p>Headset reach, tracked-hand comfort and Quest performance still need a headset session. The discrete stops have visible feedback; controller vibration or force feedback has not been added.</p>
<p><a href="implementation.md">Implementation and test notes</a> · <a href="source-hashes.json">Source hashes</a></p></section>
</main><footer>Moving 3D control · Flat surface text · Headset comparison pending</footer></body></html>'''
(DEST/'index.html').write_text(page, encoding='utf-8')
link = '<p><a href="../2026-09-21-interface-physical-slider-review/index.html">Continue: a physical handle with flat lettering.</a></p>'
if link not in previous:
    PREVIOUS.write_text(previous.replace('<footer>', '<footer>'+link), encoding='utf-8')
print(DEST/'index.html')
