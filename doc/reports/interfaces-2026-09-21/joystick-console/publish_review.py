from pathlib import Path
import hashlib, html, json, re, shutil, urllib.request
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
DEST=ROOT/'doc/book/iterations/2026-09-21-interface-joystick-review'
PREVIOUS=ROOT/'doc/book/iterations/2026-09-21-interface-mounted-console-review/index.html'
DEST.mkdir(parents=True,exist_ok=True)
focused=json.loads((HERE/'after/checks.json').read_text(encoding='utf-8'))
regression=json.loads((HERE/'regression/instrument-checks.json').read_text(encoding='utf-8'))
assert not focused['failures'] and not regression['failures']
for variant in ('after','regression'):
    assert 'SCRIPT ERROR' not in (HERE/variant/'run.log').read_text(encoding='utf-8',errors='replace')
for variant in ('before','after'):
    for p in (HERE/variant).glob('*.png'): shutil.copy2(p,DEST/(variant+'-'+p.name))
    shutil.copy2(HERE/variant/'checks.json',DEST/(variant+'-checks.json'))
shutil.copy2(HERE/'regression/instrument-checks.json',DEST/'regression-checks.json')
shutil.copy2(HERE/'regression/reference-braun.png',DEST/'mixed-console.png')
shutil.copy2(HERE/'README.md',DEST/'implementation.md')
sources=['commons/interactables/'+n for n in ['physical_joystick.gd','joystick_driver.gd','joystick_pointer_body.gd','joystick_handle.gd','joystick_smooth.tscn','joystick_snap.tscn','joystick_zero.tscn','InteractableDemo.gd','interactable_joystick_demo.tscn']]
sources+=['commons/ui/interface_joystick_reference.gd','commons/testing/test_physical_joysticks.gd']
(DEST/'source-hashes.json').write_text(json.dumps({p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in sources},indent=2),encoding='utf-8')
previous=PREVIOUS.read_text(encoding='utf-8')
css=re.search(r'<style>(.*?)</style>',previous,re.S).group(1)
def image(name,caption):
    return f'<figure><a href="{name}"><img src="{name}" width="1600" height="1200" alt="{html.escape(caption,quote=True)}"></a><figcaption>{caption}</figcaption></figure>'
total=len(focused['checks'])+regression['checks']
page=f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Let go · Ada Research</title><style>{css}</style></head><body>
<header><div class="eyebrow">Ada Research · Physical interfaces · 21 September 2026</div><h1>Let go.</h1><p class="lead">The same hand movement can leave a setting, find a detent, or return to zero.</p><p><a href="../2026-09-21-interface-mounted-console-review/index.html">Previous: the work can rise</a></p><div class="metrics"><div class="metric"><strong>3 variants</strong><span>Continuous · stepped · returning</span></div><div class="metric"><strong>2 axes</strong><span>Physical input, flat readings</span></div><div class="metric"><strong>{total} checks</strong><span>Focused and regression tests pass</span></div></div></header>
<main><section><h2>The release is part of the interface.</h2><p>Each joystick moves the orange point behind it. Move all three the same way, then let go. The first keeps its exact setting. The second keeps a setting rounded to five-degree steps. The third comes back to the centre.</p><div class="comparison">{image('after-held.png','Held: the same physical movement drives all three points; the middle control quantizes it.')}{image('after-released.png','Released: two settings remain. The right-hand joystick and its point return to zero.')}</div><p>This example represents position settings. If the receiver represented velocity, returning to centre would stop a movement instead. The receiver is part of the meaning.</p></section>
<section><h2>Make the grasp agree with the object.</h2><p>The smooth joystick’s visible ball was five centimetres beyond its grab target, and its hand-pose redirects led to missing nodes. The zero variant never enabled return-on-release. The preserved baseline confirms both defects. The repaired scenes align visible and interactive geometry and use the intended release rules.</p><div class="comparison">{image('before-controls.png','Before: original joystick components mounted in the new comparison shell.')}{image('after-controls.png','After: aligned grips, compact backed faces, signed angle readings and printed release rules.')}</div><p>The matched close-ups use the same camera. All lettering is flat on surfaces; the shafts and grips remain physical 3D objects.</p></section>
<section><h2>A reusable vocabulary</h2><div class="table-scroll"><table><thead><tr><th>Control</th><th>While moving</th><th>When released</th></tr></thead><tbody><tr><th>Continuous</th><td>Both angles vary continuously</td><td>Stays where set</td></tr><tr><th>Detented</th><td>Both angles use 5° increments</td><td>Stays at the selected steps</td></tr><tr><th>Returning</th><td>Both angles vary continuously</td><td>Returns to (0°, 0°)</td></tr></tbody></table></div><p>Both axes retain their original −45° to +45° limits. Grabbing and pointing share the same movement logic. A pointer cannot steal another pointer’s control, and losing a pointer releases a returning joystick.</p><p>The focused scene is <code>commons/interactables/interactable_joystick_demo.tscn</code>, built by the existing interactable demo’s new <code>joystick_reference</code> option. It is a reference station, not a new museum hall.</p></section>
<section><h2>Keep the existing instrument working.</h2>{image('mixed-console.png','The repaired joystick inside the existing Body / Transform console, alongside size, turn and reset.')}<p>The three existing joystick scene paths remain in use. The shared ControlPanel, component demo and other source consumers can receive the improvements on reload. The Body / Transform console passes its existing tests in both visual skins; all dependent halls have not yet been reviewed.</p></section>
<section><h2>What we checked</h2><p><strong>{len(focused['checks'])} focused checks</strong> exercise real XR Tools pickup, grab-driver movement and release, collider ray hits, readouts, visible receivers, limits, detents, stationary hands, pointer cancellation and rotated placement. <strong>{regression['checks']} existing console checks</strong> cover compatibility and reset behaviour.</p><p>These are desktop Godot captures and automated input tests. Hand-pose comfort, headset reading distance and standalone Quest frame time still need testing. The case is 86 cm wide, with controls 27 cm apart at metre scale; this is a layout to try with bodies, not a universal reach standard.</p><p><a href="after-checks.json">Focused checks</a> · <a href="regression-checks.json">Console regression</a> · <a href="before-checks.json">Baseline defects</a> · <a href="implementation.md">Source, method and reproduction</a> · <a href="source-hashes.json">Source hashes</a></p><p>Next: take two-axis physical control into a spatial encounter, and make clear whether the hand sets a position or commands movement.</p></section></main><footer>Physical controls · Flat text · A visible consequence for the hand</footer></body></html>'''
(DEST/'index.html').write_text(page,encoding='utf-8')
link='<p><a href="../2026-09-21-interface-joystick-review/index.html">Continue: let go — physical controls in two axes</a></p>'
if link not in previous: PREVIOUS.write_text(previous.replace('<footer>','<footer>'+link),encoding='utf-8')
plan=ROOT/'doc/reports/interfaces-2026-09-20/coverage-plan.md'
text=plan.read_text(encoding='utf-8')
update='Latest physical principle (21 September): [the joystick family](../../book/iterations/2026-09-21-interface-joystick-review/index.html) now has aligned grab geometry, continuous/5-degree-detented/returning variants, compact flat readouts, and a focused `interactable_joystick_demo` with visible point receivers. 97 focused and 46 mixed-console checks pass. The preceding [mounting boundary](../../book/iterations/2026-09-21-interface-mounted-console-review/index.html) is also implemented for Grammar, Fitness and Edge. Next: inspect two-axis input in a spatial encounter; distinguish position settings from velocity commands.\n\n'
if update not in text:
    text=text.replace('\n21 September correction:', '\n'+update+'21 September correction:',1)
    plan.write_text(text,encoding='utf-8')
url='http://localhost:3003/book-review/'+DEST.relative_to(ROOT).as_posix()+'/'
for name in ['index.html']+re.findall(r'<img src="([^"]+)"',page):
    with urllib.request.urlopen(url+name,timeout=15) as response:
        assert response.status==200,(name,response.status)
print(url+'index.html')
print(total,'passing checks; review and images served successfully')
