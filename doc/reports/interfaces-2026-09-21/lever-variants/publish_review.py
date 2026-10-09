from pathlib import Path
import hashlib, json, re, shutil, urllib.request

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
SLUG='2026-09-21-interface-lever-review'
dest=ROOT/'doc/book/iterations'/SLUG
dest.mkdir(parents=True,exist_ok=True)
lever=json.loads((HERE/'after/checks.json').read_text(encoding='utf-8'))
hall=json.loads((HERE/'after/radio/report.json').read_text(encoding='utf-8'))
assert not lever['failures'] and not hall['failures']
for folder in [HERE/'after',HERE/'after/radio']:
    assert 'SCRIPT ERROR' not in (folder/'run.log').read_text(encoding='utf-8',errors='replace')
for stage,names in [('before',['controls']),('after',['controls','overview','held','released'])]:
    for name in names:shutil.copy2(HERE/stage/(name+'.png'),dest/(stage+'-'+name+'.png'))
    shutil.copy2(HERE/stage/'checks.json',dest/(stage+'-checks.json'))
for name in ['radio-operating','radio-approach']:
    shutil.copy2(HERE/'after/radio'/(name+'.png'),dest/(name+'.png'))
shutil.copy2(HERE/'after/radio/report.json',dest/'point-one-checks.json')
shutil.copy2(HERE/'README.md',dest/'implementation.md')
sources=[
    'commons/maps/Point_One/map_data.json','commons/maps/Point_One/artifacts.md',
    'commons/data/artifact_roles.json','commons/interactables/physical_angular_control.gd',
    'commons/interactables/lever_smooth.tscn','commons/interactables/lever_snap.tscn',
    'commons/interactables/lever_zero.tscn','commons/interactables/angular_driver.gd',
    'commons/interactables/angular_handle.gd','commons/interactables/InteractableDemo.gd',
    'commons/interactables/interactable_lever_demo.tscn','commons/ui/interface_lever_reference.gd',
    'commons/audio/rack_configs/SoundscapeRadioRack.gd','commons/audio/rack_configs/SoundscapeRadioRack.tscn',
    'commons/testing/test_lever_variants.gd','commons/testing/probe_point_one_radio.gd',
]
(dest/'source-hashes.json').write_text(json.dumps({p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in sources},indent=2),encoding='utf-8')
prior=ROOT/'doc/book/iterations/2026-09-21-interface-radio-review/index.html'
style=re.search(r'<style>(.*?)</style>',prior.read_text(encoding='utf-8'),re.S).group(1)
html='''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>What stays when you let go? · Ada Research</title><style>STYLE</style></head><body><main>
<div class="eyebrow">Ada Research · Interface workshop · 21 September 2026</div>
<h1>What stays<br>when you let go?</h1>
<p class="lead">The radio is ready to try in Point_One. The next console gives the same hand three different rules.</p>
<span class="badge">142 lever and hall checks pass</span><span class="badge pending">Headset test still needed</span>
<h2>The radio has a place</h2>
<figure><a href="radio-approach.png"><img src="radio-approach.png" alt="The real soundscape radio on its plinth in the Point One museum hall"></a><figcaption>Point_One, source cell (3,4), facing minus Z. The radio is a secondary test station beside the point encounter.</figcaption></figure>
<p>Two full-size wheels, a readable face and a 0.85 m support. The primary lesson and its artifacts remain intact. Reload the updated Point_One map to try the radio.</p>
<figure><a href="radio-operating.png"><img src="radio-operating.png" alt="View from a standing operating position in front of the Point One radio" loading="lazy"></a><figcaption>Actual museum view. The grip heights are about 0.97–1.06 m above the floor. A standing position 0.78 m from the radio centre clears the plinth; all eight grips have clear interaction rays.</figcaption></figure>
<p>The hall check uses the actual floor and colliders, then drives both wheels through XRTools pickup. It checks a supported final metre of approach, not a complete visit or human comfort. The grips partly obscure their lower numeric readouts from this standing view; an inclined mount is the next refinement to test. Sound quality and standalone Quest performance remain open.</p>
<h2>Same hand, three laws</h2>
<figure><a href="after-overview.png"><img src="after-overview.png" alt="Three physical levers grouped in a compact inclined console in front of matching receivers" loading="lazy"></a><figcaption>The controls sit at 24 cm centres. Each moves an otherwise identical receiver behind the console.</figcaption></figure>
<div class="pair"><figure><a href="after-held.png"><img src="after-held.png" alt="Levers held at the same hand angle: continuous 23 degrees, stepped 25 degrees, returning 23 degrees" loading="lazy"></a><figcaption><strong>Held at 23°.</strong> The middle lever accepts the nearest 5° step.</figcaption></figure><figure><a href="after-released.png"><img src="after-released.png" alt="Released levers: continuous stays at 23 degrees, stepped stays at 25, returning comes back to zero" loading="lazy"></a><figcaption><strong>Released.</strong> Two keep their settings. The third returns to zero.</figcaption></figure></div>
<p>The old zero lever did not return at all. It now returns immediately on release, including pointer exit or focus loss. It is a return rule, not a simulated spring. The stepped lever keeps the native 5° detents.</p>
<h2>One base, meaningful differences</h2>
<div class="pair"><figure><a href="before-controls.png"><img src="before-controls.png" alt="Before: repaired smooth lever beside two smaller old lever variants" loading="lazy"></a><figcaption>Before: the variants still carried the old plates and input implementation.</figcaption></figure><figure><a href="after-controls.png"><img src="after-controls.png" alt="After: all lever variants share full-size plates, physical handles and printed readouts" loading="lazy"></a><figcaption>After: shared geometry, flat text, different behavior.</figcaption></figure></div>
<p>The two variants now inherit the repaired base. Their hand poses and scene identities remain available to existing consumers. Slow pointer drags accumulate across a step instead of losing every small movement to rounding.</p>
<p>The focused reference is <code>interactable_lever_demo.tscn</code>, an opt-in configuration of InteractableDemo. Its 100 checks cover physical pickup, ray dispatch, tilted and rotated mounts, limits, release rules, tiny drag increments and agreement between controls and receivers. The radio hall adds 42 checks. The previous angular and radio suites also pass after the shared changes.</p>
<div class="note">These are actual Godot renders and synthetic input through the real control code. Tracked-hand comfort, seated reach, small-text legibility and listening still need the headset. The two unresolved legacy Nostromo sound IDs remain listed in the previous radio review.</div>
<p><a href="after-checks.json">Lever checks</a> · <a href="point-one-checks.json">Point One measurements</a> · <a href="before-checks.json">Baseline findings</a> · <a href="implementation.md">Implementation and reproduction</a> · <a href="source-hashes.json">Source hashes</a></p>
<footer><a href="../2026-09-21-interface-radio-review/index.html">Previous: turn until you hear it</a><p>Next: check the component library and assembled panels that use these controls.</p></footer>
</main></body></html>'''.replace('STYLE',style)
(dest/'index.html').write_text(html,encoding='utf-8')
url='http://localhost:3003/book-review/doc/book/iterations/'+SLUG+'/index.html'
for suffix in ['index.html']+re.findall(r'<img src="([^"]+)"',html):
    with urllib.request.urlopen(url.rsplit('/',1)[0]+'/'+suffix,timeout=20) as response:assert response.status==200
print(url)
print('Review and every displayed image served successfully.')
