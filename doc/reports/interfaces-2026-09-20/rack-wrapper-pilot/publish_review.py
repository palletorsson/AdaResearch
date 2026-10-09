"""Publish the tested standalone screen bridge and actual artifact adoption."""
from pathlib import Path
import difflib
import hashlib
import json
import re
import shutil

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
DEST = ROOT/'doc/book/iterations/2026-09-20-interface-rack-wrapper-review'
PREVIOUS = ROOT/'doc/book/iterations/2026-09-20-interface-release-review/index.html'
for path in [HERE/'checks.json', HERE/'module-regression/checks.json']:
    assert not json.loads(path.read_text(encoding='utf-8'))['failures']
DEST.mkdir(parents=True, exist_ok=True)
for name in ['grammar-controls.png', 'grammar-artifact.png', 'checks.json']:
    shutil.copy2(HERE/name, DEST/name)
shutil.copy2(HERE/'module-regression/checks.json', DEST/'module-checks.json')
changes, hashes = [], {}
for relative in ['commons/audio/rack_controls/vr_wrappers/VRRackControl.gd',
                 'commons/audio/rack_controls/vr_wrappers/ModuleFaceTexture.gd',
                 'commons/audio/rack_controls/vr_wrappers/rack_pointer_surface.gd',
                 'commons/interactables/artifact_controls.gd',
                 'commons/artifacts/grammar_provenance/grammar_provenance.gd',
                 'commons/testing/test_rack_wrapper_input.gd']:
    old, new = HERE/'before'/Path(relative).name, ROOT/relative
    hashes[relative] = {'before': hashlib.sha256(old.read_bytes()).hexdigest() if old.exists() else None,
                        'after': hashlib.sha256(new.read_bytes()).hexdigest()}
    changes.extend(difflib.unified_diff(old.read_text(encoding='utf-8').splitlines(True) if old.exists() else [],
                   new.read_text(encoding='utf-8').splitlines(True), fromfile='before/'+relative, tofile=relative))
for dest in [HERE, DEST]:
    (dest/'source-hashes.json').write_text(json.dumps(hashes, indent=2), encoding='utf-8')
    (dest/'changes.diff').write_text(''.join(changes), encoding='utf-8')
css = re.search(r'<style>(.*?)</style>', PREVIOUS.read_text(encoding='utf-8'), re.S).group(1)
page = f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>From control to form · Ada Research</title><style>{css}</style></head>
<body><header><div class="eyebrow">Ada Research · Interface integration · 20 September 2026</div>
<h1>From control<br>to form.</h1><p class="lead">Stand in front of the controls and look into the work. The grammar station is now centred in front of its three forms, lowered and inclined so the forms and their descriptions remain visible behind it.</p>
<p><a href="../2026-09-20-interface-release-review/index.html">Previous: what happens when you let go?</a> · <a href="/necklace/thread?map=LSystems_Grammar_Lab&amp;role=primary">Grammar hall context</a></p>
<div class="metrics"><div class="metric"><strong>6 positions</strong><span>One selection for each existing generation</span></div><div class="metric"><strong>5 → 25</strong><span>Rendered segments in the first grammar, generation 1 → 2</span></div><div class="metric"><strong>46 + 43</strong><span>Wrapper/consumer checks and module regression checks</span></div></div></header><main>
<section><h2>The interface in front of the work</h2><figure class="hero-image"><a href="grammar-artifact.png?placement=front"><img src="grammar-artifact.png?placement=front" width="1600" height="1200" alt="A central inclined depth station in front of three grammar forms and their visible provenance boards"></a><figcaption>Player → controls → work. Standing view from local height 1.65 m in the artifact test scene. The station no longer sits beside the forms.</figcaption></figure>
<p>The old continuous slider was already rounded to an integer inside the artifact. A six-position selector now makes that rule visible. It stays at the chosen generation after release. Its position, the depth display and the generated geometry agree.</p>
<p>The status label is 2D on a backed screen, and updates when its text changes. The grammar rules and provenance text are preserved.</p></section>
<section><h2>The whole connection is tested</h2><p>The test casts physics rays at the real screen collider. Their hits become pointer events, then viewport GUI events, then the artifact's own callback. Selecting generation two changes the first grammar from 10 to 50 line vertices: five segments become twenty-five.</p>
<figure><a href="grammar-controls.png?placement=front"><img src="grammar-controls.png?placement=front" width="1600" height="1200" alt="Close view of the six-position depth selector and flat Depth 2 display on their inclined supporting case"></a><figcaption>Close view of the actual working station. These are artifact test-scene captures, not museum-hall captures.</figcaption></figure></section>
<section><h2>Shared repairs</h2><ul><li>Individual rack cases and complete module faces use the same pointer bridge. Hit bounds follow the visible screen inside the bezel, even when rotated or scaled.</li><li>Only the pointer that started a drag can change or end it. Leaving the screen, losing focus or removing that pointer releases the control.</li><li>Passive meters and labels have no pointer collider. They remain displays.</li><li>The artifact helper's buttons now listen to the signal the rack button actually emits. One press invokes one action; release does not repeat it.</li><li>Labels and initial values survive construction. A discrete value is quantized using its configured step count.</li></ul>
<p>The 2D drawing now scales as a whole, including the lettering, rather than stretching the control rectangle around undersized text. These are shared implementation changes; each placement still needs inspection.</p></section>
<section><h2>Use the existing helper</h2><pre><code>controls.add_stepped_slider(
    "DEPTH", float(generation_depth - 1) / 5.0,
    func(value): generation_depth = roundi(value * 5.0) + 1,
    6
)
controls.add_label("depth_display", "Depth: 2")
controls.update_label("depth_display", "Depth: 3")</code></pre>
<p><code>VRRackControl</code> now supports pointing at the screen. This does not create a physical grab handle. Controls can explicitly disable the pointer route; inner components still need their own working GUI behaviour.</p></section>
<section><h2>Evidence and next placements</h2><p><a href="checks.json">46 standalone and artifact checks</a> pass, together with <a href="module-checks.json">43 regression checks for the complete module panel</a>. The latter reuse the earlier test with private output paths, preserving the earlier review evidence.</p>
<p>Headset reach, tracked hands, Quest performance and museum sightlines remain untested here. Existing startup UID, certificate and shader-cache warnings are recorded; the final runs have no script errors and exit successfully.</p>
<p>Next are the fitness-landscape and edge-of-chaos control assemblies: their actions, selected modes and deliberately restricted controls. The rack wheel and lever also still need their inner input handlers; a working wrapper alone does not make those prototypes functional.</p>
<p><a href="changes.diff">Exact changes</a> · <a href="source-hashes.json">Source hashes</a></p></section>
</main><footer>Standalone pointer input connected · Grammar receiver verified · Headset checks pending</footer></body></html>'''
(DEST/'index.html').write_text(page, encoding='utf-8')
prior = PREVIOUS.read_text(encoding='utf-8')
link = '<p><a href="../2026-09-20-interface-rack-wrapper-review/index.html">Continue: standalone controls reach the grammar artifact.</a></p>'
if link not in prior:
    PREVIOUS.write_text(prior.replace('<footer>', '<footer>'+link), encoding='utf-8')
print(DEST/'index.html')
