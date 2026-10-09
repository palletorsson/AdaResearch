"""Publish real control-state captures and source provenance; no live map writes."""
from pathlib import Path
import difflib
import hashlib
import json
import re
import shutil

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
DEST = ROOT / 'doc/book/iterations/2026-09-20-interface-release-review'
PREVIOUS = ROOT / 'doc/book/iterations/2026-09-20-interface-shannon-review/index.html'

report = json.loads((HERE/'checks.json').read_text(encoding='utf-8'))
assert not report['failures']
DEST.mkdir(parents=True, exist_ok=True)
for name in ('held.png', 'released.png', 'surface.png', 'checks.json'):
    shutil.copy2(HERE/name, DEST/name)
hashes, changes = {}, []
paths = ['commons/audio/rack_controls/RackControlBase.gd',
         'commons/audio/rack_controls/RackSliderStepped.gd',
         'commons/audio/rack_controls/RackSliderBipolar.gd',
         'commons/audio/rack_controls/vr_wrappers/ModuleFaceTexture.gd',
         'commons/interactables/InteractableDemo.gd',
         'commons/interactables/interactable_release_demo.tscn',
         'commons/ui/interface_release_reference.gd',
         'commons/testing/test_rack_release_controls.gd']
for relative in paths:
    before = HERE/'before'/Path(relative).name
    after = ROOT/relative
    hashes[relative] = {'before': hashlib.sha256(before.read_bytes()).hexdigest() if before.exists() else None,
                        'after': hashlib.sha256(after.read_bytes()).hexdigest()}
    changes.extend(difflib.unified_diff(before.read_text(encoding='utf-8').splitlines(True) if before.exists() else [],
                   after.read_text(encoding='utf-8').splitlines(True), fromfile='before/'+relative, tofile=relative))
for folder in (HERE, DEST):
    (folder/'source-hashes.json').write_text(json.dumps(hashes, indent=2), encoding='utf-8')
    (folder/'changes.diff').write_text(''.join(changes), encoding='utf-8')
css = re.search(r'<style>(.*?)</style>', PREVIOUS.read_text(encoding='utf-8'), re.S).group(1)
page = f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>What happens when you let go? · Ada Research</title><style>{css}</style></head>
<body><header><div class="eyebrow">Ada Research · Interface principles · 20 September 2026</div>
<h1>What happens<br>when you let go?</h1><p class="lead">A choice stays selected. A command returns to zero. A signed setting can stay where you left it. The interface should make that difference visible.</p>
<p><a href="../2026-09-20-interface-shannon-review/index.html">Previous: Shannon console</a> · <a href="/interface-presets-gallery">Principal interface gallery</a></p>
<div class="metrics"><div class="metric"><strong>3 behaviours</strong><span>Choice · returning command · retained setting</span></div><div class="metric"><strong>57.6 cm</strong><span>Shared panel face, with a case and pedestal</span></div><div class="metric"><strong>{report['checks']} checks</strong><span>Pointer → screen → value → visible receiver</span></div></div></header><main>
<section><h2>Hold, then release</h2><p>The orange marker stays at choice five. The purple setting stays at −0.50. The blue command is +1 while held and returns to zero when released. These captures show two states of the same working Godot reference, from the same camera.</p>
<div class="comparison" role="group" aria-label="Release comparison"><input type="radio" name="view" id="view-after" checked><label for="view-after">After release</label><input type="radio" name="view" id="view-before"><label for="view-before">While held</label>
<figure class="hero-image after-view"><a href="released.png"><img src="released.png" width="1600" height="1200" alt="The blue command and marker have returned to centre, while the orange choice and purple setting remain"></a><figcaption>Release: only the blue command returns to zero. Its marker, handle and readout agree.</figcaption></figure>
<figure class="hero-image before-view"><a href="held.png"><img src="held.png" width="1600" height="1200" alt="The blue command is held at plus one, with its marker at the top of the rail"></a><figcaption>Held: the blue command raises its marker to the top. Orange and purple retain their values.</figcaption></figure></div></section>
<section><h2>The control tells you what will persist</h2><figure><a href="surface.png"><img src="surface.png" width="1600" height="1200" alt="Close view of three backed faders, with value windows, discrete notches, zero marks and printed release behaviour"></a><figcaption>All text is 2D on the supporting panel. Colour connects each handle to its marker; words distinguish the release behaviour.</figcaption></figure>
<p>The stepped slider now changes the stored value in discrete steps. Its receiver gets the same value that the handle shows. The bipolar slider supports both return and retention: having negative and positive values does not, by itself, decide what release should do.</p>
<p>The returning control resets immediately. This demonstrates the input contract; it does not simulate spring dynamics. A force or velocity receiver can use the same contract later, but these markers only show the current value.</p></section>
<section><h2>Repair the route, not only the appearance</h2><p>The census found that these two rack controls drew a handle but inherited empty pointer handlers. They now handle pressing and dragging. A separate layout defect was also found: entering the scene tree discarded the larger cell dimensions allocated by the panel. Those dimensions now survive.</p>
<p>The existing module panel converts a 3D hit into a 2D GUI event. We tested that whole route and the resulting marker movement. An active drag now belongs to its initiating pointer: another pointer cannot move or release it. Leaving the panel releases a returning command.</p></section>
<section><h2>A reusable reference</h2><p>Open <code>commons/interactables/interactable_release_demo.tscn</code> in Godot, or set <code>release_reference = true</code> on <code>InteractableDemo</code>. The full sampler remains available. The reference uses the existing shared module panel and canonical rack controls.</p>
<pre><code># Control entries supplied to ModuleFaceTexture.build():
{{"type": "sls", "step_count": 5}}  # Discrete choice; persists
{{"type": "slz", "return_to_center": true}}  # Command; returns
{{"type": "slz", "return_to_center": false}} # Setting; persists</code></pre>
<p>The signal remains normalized from 0 to 1. For the bipolar control, 0.5 is signed zero; <code>get_signed_value()</code> returns −1 to +1. Consumers retain control of their own units and effects.</p></section>
<section><h2>Evidence and what remains</h2><p><a href="checks.json">All {report['checks']} automated checks pass</a>: endpoints, between-notch input, programmatic assignment, step-count changes, release, exit, competing pointers, receiver agreement, rotated/scaled placement and continuous-slider regression. The renderer is Godot Mobile on the desktop GPU. Pointer events use generated hit coordinates and actual viewport GUI dispatch.</p>
<p>Headset reach, tracked hands and Quest performance still need testing. No museum hall was moved or replaced in this pass.</p><p>The standalone <code>VRRackControl</code> wrapper is the next integration gap. It renders a screen and case but has no pointer forwarding of its own. Repairing its inner slider does not yet make that wrapper interactive. Audio and artifact consumers also need their intended release behaviour checked before wider adoption.</p>
<p><a href="changes.diff">Exact source changes</a> · <a href="source-hashes.json">Source hashes</a></p></section>
</main><footer>Working reference added to InteractableDemo · Shared rack controls repaired · Headset checks pending</footer></body></html>'''
(DEST/'index.html').write_text(page, encoding='utf-8')
previous = PREVIOUS.read_text(encoding='utf-8')
link = '<p><a href="../2026-09-20-interface-release-review/index.html">Continue: choice, return and retention.</a></p>'
if link not in previous:
    PREVIOUS.write_text(previous.replace('<footer>', '<footer>'+link), encoding='utf-8')
print(DEST/'index.html')
