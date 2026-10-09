from pathlib import Path
import hashlib, json, re, shutil, urllib.request

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
slug='2026-09-21-interface-xy-pad-review'
dest=ROOT/'doc/book/iterations'/slug
dest.mkdir(parents=True,exist_ok=True)
checks=json.loads((HERE/'after/checks.json').read_text(encoding='utf-8'))
assert not checks['failures']
assert 'SCRIPT ERROR' not in (HERE/'after/run.log').read_text(encoding='utf-8')
count=len(checks['checks'])
for stage,names in [('before',['pad','console','operating']),('after',['pad','console','operating','changed','subtraction'])]:
    for name in names:
        shutil.copy2(HERE/stage/(name+'.png'),dest/(stage+'-'+name+'.png'))
    shutil.copy2(HERE/stage/'checks.json',dest/(stage+'-checks.json'))
shutil.copy2(HERE/'README.md',dest/'implementation.md')
source_files=[
    'commons/interactables/physical_xy_pad.gd','commons/interactables/slider_plane.gd',
    'commons/interactables/slider_plane.tscn','commons/interactables/joystick_pointer_body.gd',
    'commons/interactables/joystick_handle.gd','commons/artifacts/_toy_console/toy_console.gd',
    'commons/artifacts/vector_op_console/vector_op_console.gd',
    'commons/interactables/InteractableDemo.gd','commons/interactables/interactable_xy_demo.tscn',
    'commons/audio/UniversalVRAudioController.gd','commons/ui/demo/vr_component_demo.gd',
    'commons/testing/test_physical_xy_pad.gd',
]
(dest/'source-hashes.json').write_text(json.dumps({p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in source_files},indent=2),encoding='utf-8')
html='''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Two coordinates · Ada Research</title><style>
:root{color-scheme:dark}*{box-sizing:border-box}body{margin:0;background:#141b20;color:#eef0e7;font:17px/1.65 system-ui,sans-serif}main{max-width:1180px;margin:auto;padding:48px 26px 80px}a{color:#ffc29d}h1{font-size:clamp(36px,6vw,68px);line-height:1.08;max-width:850px}h2{font-size:28px;margin-top:54px}p{max-width:820px}.eyebrow{letter-spacing:.12em;text-transform:uppercase;font-size:13px;color:#a9b8b8}.lead{font-size:23px;color:#d8e3df}.badge{display:inline-block;padding:5px 14px;background:#283c39;border:1px solid #487b68;border-radius:24px;margin:4px 8px 4px 0}.pending{background:#382f29;border-color:#8a684c}.pair{display:grid;grid-template-columns:1fr 1fr;gap:22px}figure{margin:22px 0}img{display:block;width:100%;height:auto;border:1px solid #475653;border-radius:8px}figcaption{color:#b9c6c4;font-size:14px;margin:10px 0}.note{border-left:3px solid #df8d53;padding:12px 22px;background:#202b31}table{width:100%;border-collapse:collapse;font-size:16px}td,th{text-align:left;padding:14px;border-bottom:1px solid #44524f;vertical-align:top}code{overflow-wrap:anywhere;font-size:.86em}footer{margin-top:60px;border-top:1px solid #44524f;padding-top:24px}@media(max-width:700px){.pair{grid-template-columns:1fr}main{padding:28px 18px}table{font-size:14px}td,th{padding:9px}}
</style></head><body><main>
<div class="eyebrow">Ada Research · Interface workshop · 21 September 2026</div>
<h1>Two coordinates.<br>One place for the hand.</h1>
<p class="lead">The pad, the number and the arrow now describe the same position.</p>
<span class="badge">COUNT desktop checks pass</span><span class="badge pending">Headset validation pending</span>
<p>Following the joystick pass, we took the physical XY pad into an existing vector encounter. The two controls sit together in front of the work: move a tip, let go, and inspect what the two vectors make.</p>
<figure><a href="after-operating.png"><img src="after-operating.png" alt="The vector console from an operating position, with two closely grouped physical pads and arrows visible behind them"></a><figcaption>Actual Godot render. Camera at 1.60 m; this is a declared desktop viewpoint, not a measured reach verdict.</figcaption></figure>
<h2>The knob must stay on its plane</h2>
<p>The old pad inherited a one-axis constraint script. Its face and movement used different planes, and its grab target missed the visible knob. A larger custom bezel in the vector console tried to compensate. The shared component now supplies the complete working pad.</p>
<div class="pair"><figure><a href="before-pad.png"><img src="before-pad.png" alt="Original XY pad with misaligned knob and floating value text" loading="lazy"></a><figcaption>Before: original component, captured before editing.</figcaption></figure><figure><a href="after-pad.png"><img src="after-pad.png" alt="Repaired pad with physical orange grip, coordinate grid, and flat signed X and Y reading" loading="lazy"></a><figcaption>After: both coordinates travel across the face. The reading is a flat screen seated on the backing.</figcaption></figure></div>
<h2>Bring the controls together</h2>
<div class="pair"><figure><a href="before-console.png"><img src="before-console.png" alt="Original vector console with separated pad assemblies" loading="lazy"></a><figcaption>Before: 52 cm between pad centres, with an extra bezel and rotation workaround.</figcaption></figure><figure><a href="after-console.png"><img src="after-console.png" alt="Revised vector console with two compact pads on supported inclined mounts" loading="lazy"></a><figcaption>After: 30 cm between centres, full-size controls, and the vector diagram behind them. The camera is unchanged.</figcaption></figure></div>
<table><thead><tr><th>What the hand does</th><th>What changes</th><th>What remains on release</th></tr></thead><tbody>
<tr><td>Move a-TIP</td><td>The first vector and its contribution to the result</td><td>The selected position</td></tr>
<tr><td>Move b-TIP</td><td>The second vector and its contribution to the result</td><td>The selected position</td></tr>
<tr><td>Reconfigure addition / subtraction</td><td>The arithmetic, heading, readout and synchronized pad positions</td><td>The same physical controls stay in place</td></tr>
</tbody></table>
<div class="pair"><figure><a href="after-changed.png"><img src="after-changed.png" alt="The result after a real pointer event changes the first vector" loading="lazy"></a><figcaption>Input evidence: pointer drag changes a to (+0.50, −0.50), with corresponding readout and geometry.</figcaption></figure><figure><a href="after-subtraction.png"><img src="after-subtraction.png" alt="Subtraction variant with flat algebra board and synchronized controls" loading="lazy"></a><figcaption>The existing expression variant remains available. Its algebra is now printed on a flat surface.</figcaption></figure></div>
<h2>A reusable control, a specific encounter</h2>
<p>The existing <code>slider_plane.tscn</code> path now supplies the repaired physical pad. Its child keeps the historical Vector2-in-metres contract; the wrapper adds explicit signed normalized positions and display scaling. Grabs and pointers agree, including after rotating the console.</p>
<p><code>interactable_xy_demo.tscn</code> is a focused InteractableDemo configuration using the actual vector console. The same code serves the registry’s <code>vector_add</code> and <code>vector_sub</code> scenes. The <code>room_gap</code> variant substitutes another encounter and remains outside this verification.</p>
<p>These are position settings. A control that commands velocity or force needs a different receiver and a different release explanation; that distinction remains part of the next pass.</p>
<h2>Evidence and limits</h2>
<p>COUNT checks cover real XR Tools pickup and release, ray-hit pointer dispatch, tilted and rotated axes, limits, optional detents and spring return, input ownership, operand synchronization, visible arithmetic and four sibling-console construction regressions. The successful run has no script errors.</p>
<div class="note"><strong>Still to try in the headset:</strong> hand comfort, shorter and seated positions, Quest text legibility and frame time. These captures show the actual artifacts in a desktop fixture, not a complete museum walk. Receiver geometry still rebuilds after edits; this pass makes no Quest performance claim.</div>
<p><a href="after-checks.json">All checks</a> · <a href="before-checks.json">Baseline findings</a> · <a href="implementation.md">Implementation and reproduction notes</a> · <a href="source-hashes.json">Captured source hashes</a></p>
<footer><a href="../2026-09-21-interface-joystick-review/index.html">Previous: grab, move, let go</a><p>Next: examine wheel and lever controls in their exhibits, including what their angle means.</p></footer>
</main></body></html>'''.replace('COUNT',str(count))
(dest/'index.html').write_text(html,encoding='utf-8')
prior=ROOT/'doc/book/iterations/2026-09-21-interface-joystick-review/index.html'
previous=prior.read_text(encoding='utf-8')
if slug not in previous:
    previous=previous.replace('</body>',f'<p style="max-width:1100px;margin:30px auto;padding:20px"><a href="../{slug}/index.html">Next: the physical XY pad in the vector console</a></p></body>')
    prior.write_text(previous,encoding='utf-8')
url='http://localhost:3003/book-review/doc/book/iterations/'+slug+'/index.html'
with urllib.request.urlopen(url,timeout=20) as response:
    assert response.status==200
for name in re.findall(r'<img src="([^"]+)"',html):
    with urllib.request.urlopen(url.rsplit('/',1)[0]+'/'+name,timeout=20) as response:
        assert response.status==200
print(url)
print(count,'passing checks; review and displayed images served successfully')
