from pathlib import Path
import hashlib
import json
import re
import shutil
import urllib.request

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
SLUG = '2026-09-21-interface-angular-review'
dest = ROOT / 'doc/book/iterations' / SLUG
dest.mkdir(parents=True, exist_ok=True)
checks = json.loads((HERE / 'after/checks.json').read_text(encoding='utf-8'))
assert not checks['failures']
assert 'SCRIPT ERROR' not in (HERE / 'after/run.log').read_text(encoding='utf-8')
count = len(checks['checks'])
for stage, names in [('before', ['controls']), ('after', ['controls', 'overview', 'operating', 'console', 'held', 'released'])]:
    for name in names:
        shutil.copy2(HERE / stage / (name + '.png'), dest / (stage + '-' + name + '.png'))
    shutil.copy2(HERE / stage / 'checks.json', dest / (stage + '-checks.json'))
shutil.copy2(HERE / 'README.md', dest / 'implementation.md')
sources = [
    'commons/interactables/angular_driver.gd',
    'commons/interactables/angular_handle.gd',
    'commons/interactables/physical_angular_control.gd',
    'commons/interactables/wheel_smooth.tscn',
    'commons/interactables/lever_smooth.tscn',
    'commons/interactables/joystick_pointer_body.gd',
    'commons/interactables/InteractableDemo.gd',
    'commons/interactables/interactable_angular_demo.tscn',
    'commons/ui/interface_angular_reference.gd',
    'commons/audio/UniversalVRAudioController.gd',
    'commons/ui/demo/vr_component_demo.gd',
    'commons/testing/test_physical_angular_controls.gd',
]
(dest / 'source-hashes.json').write_text(json.dumps({p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in sources}, indent=2), encoding='utf-8')
previous = ROOT / 'doc/book/iterations/2026-09-21-interface-xy-pad-review/index.html'
old = previous.read_text(encoding='utf-8')
style = re.search(r'<style>(.*?)</style>', old, re.S).group(1)
html = '''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Place / keep moving · Ada Research</title><style>STYLE</style></head><body><main>
<div class="eyebrow">Ada Research · Interface workshop · 21 September 2026</div>
<h1>Place.<br>Keep moving.</h1>
<p class="lead">Turn the wheel. Pull the lever. Let go of both. What stops, and what stays?</p>
<span class="badge">COUNT desktop checks pass</span><span class="badge pending">Headset validation pending</span>
<p>The next physical interface reference makes a difference visible: a control can set a position, or command movement over time. Their handles share a compact station; their consequences remain in view behind it.</p>
<figure><a href="after-console.png"><img src="after-console.png" alt="Wheel and lever on a compact inclined case, with physical orange grips, direction marks and flat signed readings"></a><figcaption>Actual Godot capture. Full-size controls, 28 cm between centres. All lettering is printed on flat surfaces.</figcaption></figure>
<h2>The shared controls needed repair</h2>
<p>The old wheel had a 40 cm frame collider around an 8 cm wheel, and no collision shape on its rotating body. The smooth lever had two hand-pose redirects with no target. Neither component supplied a root pointer route or a reading.</p>
<div class="pair">
<figure><a href="before-controls.png"><img src="before-controls.png" alt="Original small wheel and lever before the shared component repair" loading="lazy"></a><figcaption>Before: original source, captured before editing.</figcaption></figure>
<figure><a href="after-controls.png"><img src="after-controls.png" alt="Repaired wheel and lever with matching backplates, visible grips, direction marks and flat value screens" loading="lazy"></a><figcaption>After: the same camera. Backing, visible grip, collision and reading now belong to one assembly.</figcaption></figure>
</div>
<p>The wheel now has four usable grips and a visible orientation index. Physical grabs and pointers agree, including after the station rotates. Holding still does not accumulate rotation; regrabbing beyond a half-turn preserves the current angle. Releasing a grip also preserves its pointer targeting.</p>
<h2>One station, two meanings</h2>
<table><thead><tr><th>Control</th><th>What it changes</th><th>On release</th></tr></thead><tbody>
<tr><td>Wheel · set angle</td><td>The orange bar takes the selected angle.</td><td>Wheel and bar stay where you left them.</td></tr>
<tr><td>Lever · command speed</td><td>The cyan bar keeps turning. Pull farther for more degrees per second; reverse the lever to reverse direction.</td><td>The lever returns to zero. The bar stops at its accumulated angle.</td></tr>
</tbody></table>
<div class="pair">
<figure><a href="after-held.png"><img src="after-held.png" alt="The wheel reads plus 60 degrees while the held lever commands plus 60 degrees per second" loading="lazy"></a><figcaption>Held: +60° is a position; +60°/s is a rate. The captured frame is frozen after the timed movement checks.</figcaption></figure>
<figure><a href="after-released.png"><img src="after-released.png" alt="After release the wheel retains 60 degrees, the lever reads zero degrees per second, and both bars retain their final poses" loading="lazy"></a><figcaption>Released: the command returns to zero; the movement it already produced remains.</figcaption></figure>
</div>
<p>This comparison connects transformation to change over time. It provides a basis for a later force control, whose input would change velocity rather than directly prescribe it.</p>
<h2>A reference we can reuse</h2>
<p><code>interactable_angular_demo.tscn</code> adds this encounter to InteractableDemo. The smooth wheel and lever keep their existing scene paths and native hinge APIs. The reference explicitly opts its lever into spring return; the shared smooth lever still retains its setting by default.</p>
<p>The controls stand in front of the work on an inclined case with an upright support. The operating view uses a 1.60 m camera height. The reference is ready for placement and headset trials; it is not yet a verified museum installation.</p>
<h2>What the checks establish</h2>
<p>COUNT checks cover real XR Tools pickup/release, ray-hit pointer dispatch, limits, optional detents, wheel wraparound, two simultaneous grips, input cancellation, mapped readings and the visible receivers. Half a second at 60°/s adds 30°; zero command preserves the accumulated pose and stops receiver processing. The run contains no script errors.</p>
<div class="note"><strong>Still to establish:</strong> comfort and reach in the headset, shorter and seated positions, Quest legibility and performance, and the larger controls inside existing museum placements. These are desktop captures with synthetic hand drivers using the real input APIs.</div>
<p><a href="after-checks.json">All checks</a> · <a href="before-checks.json">Baseline findings</a> · <a href="implementation.md">Implementation and reproduction notes</a> · <a href="source-hashes.json">Captured source hashes</a></p>
<footer><a href="../2026-09-21-interface-xy-pad-review/index.html">Previous: two coordinates</a><p>Next: the existing soundscape radio. Its tuning and volume wheels need an assembled review, including meaningful units, reachable size and its intentionally different display modes. The duplicated stepped and zero lever scenes also remain to migrate.</p></footer>
</main></body></html>'''.replace('STYLE', style).replace('COUNT', str(count))
(dest / 'index.html').write_text(html, encoding='utf-8')
if SLUG not in old:
    old = old.replace('</footer>', '<p><a href="../' + SLUG + '/index.html">Continue: place / keep moving</a></p></footer>')
    previous.write_text(old, encoding='utf-8')
url = 'http://localhost:3003/book-review/doc/book/iterations/' + SLUG + '/index.html'
with urllib.request.urlopen(url, timeout=20) as response:
    assert response.status == 200
for name in re.findall(r'<img src="([^"]+)"', html):
    with urllib.request.urlopen(url.rsplit('/', 1)[0] + '/' + name, timeout=20) as response:
        assert response.status == 200
print(url)
print(count, 'passing checks; review and all displayed images served successfully')
