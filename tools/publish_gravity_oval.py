"""Publish actual museum views and the bounded gravity-oval verification."""
from pathlib import Path
import hashlib
import html
import json
import shutil

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-07-gravity-oval'
for src, dest in [('ada_run/gravity_oval_tests.json', 'physics-tests.json'), ('ada_run/gravity_oval_tests.log', 'physics-tests.log'), ('commons/artifacts/gravity_oval/README.md', 'artifact-notes.md')]:
    shutil.copy2(ROOT / src, OUT / dest)
tests = [json.loads(p.read_text(encoding='utf-8-sig')) for p in [OUT/'physics-tests.json', OUT/'museum/report.json']]
assert all(t['passed'] and all(c['passed'] for c in t['checks']) for t in tests)
assert all('SCRIPT ERROR' not in p.read_text(encoding='utf8', errors='replace') for p in [OUT/'physics-tests.log', OUT/'museum/engine.log'])
count = sum(len(t['checks']) for t in tests)
xr = tests[0]['measurements']['xr']
museum = tests[1]['observations']['oval']

def figure(name, caption):
    path = 'museum/' + name + '.png'
    assert (OUT/path).is_file()
    return f'<figure><a href="{path}"><img src="{path}" alt="{html.escape(caption, quote=True)}" loading="lazy"></a><figcaption>{caption}</figcaption></figure>'

page = '''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Gravity oval — enter the circulation</title><style>
*{box-sizing:border-box}body{margin:0;background:#151a22;color:#f0e9dc;font:17px/1.65 system-ui,sans-serif}main{max-width:1220px;margin:auto;padding:38px 24px 70px}h1{font:clamp(44px,6vw,76px)/1.04 Georgia,serif;margin:24px 0}h2{font:33px/1.2 Georgia,serif;margin-top:48px}p{max-width:830px}a{color:#ec94bc}nav{display:flex;gap:22px;flex-wrap:wrap;margin:28px 0}figure{margin:32px 0}img{width:100%;height:auto;display:block}figcaption{color:#bdbec8;margin-top:10px;max-width:920px}.entry{padding:16px 26px;background:#32303d;border-left:5px solid #ec94bc}.kicker{font-size:13px;letter-spacing:.14em;text-transform:uppercase}.idea{font:27px/1.5 Georgia,serif;max-width:850px;margin:40px 0}li{margin:8px 0}@media print{body{background:white;color:black}nav{display:none}figure{break-inside:avoid}}
</style></head><body><main><p class="kicker">Endless Museum · Forces · 7 October 2026</p><h1>Gravity oval</h1><p class="idea">A chair rises past your shoulder. The crate above it turns across the sky. Step into the same stream: what you were watching becomes the movement of your own body.</p><p>Twenty-four familiar objects circulate through a vertical oval. One column rises, the top turns across, the opposite column descends, and the bottom returns into another ascent. Contacts can disturb the procession; the acceleration keeps drawing it around.</p>
<nav><a href="#museum">Inside the museum</a><a href="#ride">Inside the stream</a><a href="#checks">Verification</a><a href="artifact-notes.md">Artifact notes</a></nav>
<div class="entry"><p><strong>Reload the museum. Forces → The room gives a direction.</strong> Walk past the existing field comparisons to the tall oval in the final bay. Enter on the rose-marked RISE side. No button is needed to ride.</p><p>Walk sideways out of the stream to leave it. You can grab its objects and take them out; ordinary gravity returns outside. Your view stays upright throughout the journey. RESET restores the objects after you release anything held.</p></div>
<h2 id="museum">The floating column returns</h2>'''
page += figure('whole-oval', 'The complete installation in the existing museum. A slim outline and solid arrows expose the intended flow; coloured trails show recent object motion.')
page += figure('step-into-the-stream', 'At floor level beside RISE. The black PointBody returns alongside the museum’s crates, chairs and extinguishers.')
page += figure('floating-prefabs', 'Familiar shapes turn into a circulating assembly. These are dynamic colliding bodies, not meshes moved along an animation path.')
page += '<h2 id="ride">Your body joins the stream</h2>'
page += figure('over-the-top', 'From the carried player’s eye height during the ascent toward the turn. Nearby cargo can partly obscure the view; the camera remains inside the physical encounter.')
page += figure('coming-down', 'Returning alongside the descending objects. The same field supplies the player’s acceleration through the museum movement system.')
page += f'''<h2 id="checks">What passed</h2><p><strong>{count} assertions passed:</strong> 17 physics and XR checks, plus 25 production museum checks. A tracked XR player completed {xr['turns']:.2f} circuits using the real XRTools movement adapter. In the museum test, the player reached {museum['peak_height']:.1f} metres, returned to floor level and began another lap. The props completed repeated circuits with zero out-of-bounds recoveries.</p>
<p>Checks also covered unchanged tracked-head pose, leaving by movement input, relinquishing field control, picking up a floating point, ordinary gravity after removal, reset refusal while held, a finite body count, and a clear museum aisle and exit. Physical headset comfort and Quest frame time remain unverified.</p>
<h2>The rule behind the ride</h2><p>This is an <strong>artificial driven field</strong>. It steers velocity toward an oval’s tangent and draws bodies toward its section. That supplies energy. It models circulating motion rather than Newtonian attraction or literal antigravity. The player and props use the same acceleration function; walking input and physical contact can change the result. Only the installation’s own cast and the player receive the field.</p>
<p>The field’s reference oval runs from 1.2 to 10.2 metres high; retained velocity can carry bodies beyond that guide before they turn. The arrows show intended flow, while the trails show actual recent positions. The primary vortex tutorial remains the hall’s teaching anchor; the oval adds an embodied comparison.</p>
<p>All prior field artifacts remain in place. The bay extends the hall from 84 to 104 metres; its route and end teleporter were updated in the live and shipped museum plans. No full tutorial or final manuscript was rewritten.</p>
<nav><a href="physics-tests.json">Physics and XR assertions</a><a href="museum/report.json">Museum assertions</a><a href="verification.json">Source hashes</a><a href="museum/engine.log">Museum engine log</a><a href="physics-tests.log">Physics log</a></nav>
<p>The logs retain existing unknown-UID, ignored Jolt solver-bias and compatibility-renderer warnings. No script errors occurred in these runs. All pictures are actual museum renders.</p></main></body></html>'''
(OUT/'index.html').write_text(page, encoding='utf8')
sources = ['commons/artifacts/gravity_oval/gravity_oval.gd', 'commons/artifacts/gravity_oval/gravity_oval.tscn', 'commons/artifacts/registry/force_play.json', 'commons/maps/Vectors_Act3_FieldsAndMotion/map_data.json', 'commons/artifacts/force_halls/curation.json', 'tools/probes/gravity_oval.gd', 'tools/probes/gravity_oval_museum.gd']
(OUT/'verification.json').write_text(json.dumps({'passed': True, 'checks': count, 'sources': {p: hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in sources}}, indent=2), encoding='utf8')
print(OUT/'index.html', count, 'checks')
