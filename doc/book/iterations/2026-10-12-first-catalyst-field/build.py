"""Publish native museum evidence after the focused Godot probe passes."""
from pathlib import Path
import hashlib
import html
import json
import shutil

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
RUN = ROOT / 'ada_run/encounter_pilot/Point_Coordinates/first-catalyst'
report = json.loads((RUN / 'report.json').read_text(encoding='utf-8'))
log = (RUN / 'stdout.log').read_text(encoding='utf-8')
assert report['passed'] and not report['failures']
assert 'SCRIPT ERROR' not in log and 'Parse Error' not in log
images = [
    ('field-in-the-hall', 'A hollow field replaces the red arrows.', 'The same place in Point Coordinates, after Point One. The field floats at 1.24 metres above a simple off-white plinth.'),
    ('point-in-the-field', 'The point grants an ability.', 'Carry the existing black point into the field. Its coordinate identity and pickup behaviour remain; you can still use it in the hall.'),
    ('tracked-hands-together', 'Together: a form.', 'After the unlock, bring empty hands together. The familiar black sphere appears between them. This native render uses the museum hand models and supplied XRServer poses.'),
    ('tracked-hands-apart', 'Apart: the capacity remains.', 'The sphere disappears when the hands separate. A faint glow remains around each hand. The pink mushroom tools visible here belong to the existing hand system, not this new ability.'),
]
for name, _, _ in images:
    shutil.copy2(RUN / (name + '.png'), OUT / (name + '.png'))
sources = [
    'commons/managers/CatalystCapabilityManager.gd',
    'commons/hazards/becoming_catalyst/first_catalyst_ability.gd',
    'commons/hazards/becoming_catalyst/first_catalyst_glow.gdshader',
    'commons/artifacts/drag_point_target/first_catalyst_field.gd',
    'commons/artifacts/drag_point_target/drag_point_target.gd',
    'commons/primitives/point/point_held.gd',
    'commons/maps/Point_Coordinates/map_data.json',
    'tools/probes/first_catalyst.gd',
]
receipt = {**report, 'date': '2026-10-12', 'headset_tested': False,
           'sources': {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in sources}}
(OUT / 'checks.json').write_text(json.dumps(receipt, indent=2), encoding='utf-8')
cards = ''.join(f'<figure><a href="{n}.png"><img src="{n}.png" alt="{html.escape(t)}"></a><figcaption><h2>{t}</h2><p>{d}</p></figcaption></figure>' for n,t,d in images)
count = len(report['checks'])
checks = ''.join('<li>'+html.escape(c['name'])+'</li>' for c in report['checks'])
links = ''.join(f'<li><a href="../../../../{p}">{p}</a></li>' for p in sources)
page = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>The first catalyst · Endless Museum</title><style>
*{box-sizing:border-box}body{margin:0;background:#edece7;color:#20252a;font:18px/1.55 system-ui,sans-serif}header,main,footer{max-width:1280px;margin:auto;padding:36px}header{padding-top:64px}h1{font:clamp(36px,6vw,76px)/1.05 Georgia,serif;max-width:900px;margin:18px 0}h2{font:28px/1.2 Georgia,serif;margin:0 0 12px}p{max-width:790px}.eyebrow{letter-spacing:.12em;text-transform:uppercase;font-size:12px}.lead{font-size:23px}.status{border-left:3px solid #667e8c;padding:12px 22px;background:#fff9}figure{margin:0 0 50px;background:#fff}img{display:block;width:100%;height:auto}figcaption{padding:24px 30px}a{color:#36586b}details{padding:20px 0;border-top:1px solid #bbc1c4}code{font-size:14px}li{margin:8px 0}footer{font-size:14px;color:#52606a}.facts{display:grid;grid-template-columns:1fr 1fr;gap:24px;margin:34px 0}@media(max-width:750px){header,main,footer{padding:22px}.facts{grid-template-columns:1fr}}
</style><header><div class="eyebrow">Endless Museum · 12 October 2026 · first catalyst</div>
<h1>The point becomes a capacity.</h1><p class="lead">Carry a sphere. Place it in a hollow field. Bring your empty hands together and call its form back.</p>
<p>The sphere is the first visible form of the power. The capacity belongs to the player and can later acquire other forms and effects throughout the spine.</p>
<div class="status">Implemented in the real Coordinates hall, immediately after Point One. <b>COUNT Godot checks pass.</b> Controller poses were supplied through XRServer; a headset comfort check is still needed.</div></header><main>
CARDS
<div class="facts"><section><h2>What carries onward</h2><p>The unlock is saved with catalyst progression. It survives the originating artifact and reattaches to a replacement XR rig. The physical point remains available for the coordinate lesson.</p></section>
<section><h2>This first step</h2><p>A quiet glow and a sphere between the hands. No trigger action, projectile, damage, creature conversion or editor-tool unlock is added. Later abilities can grow from this encounter.</p></section></div>
<details><summary>Behaviour and test boundary</summary><p>The field accepts only the original coordinate point. Its centre must enter the hollow volume for 0.18 seconds. Empty tracked hands closer than 24 cm form the sphere after 0.15 seconds; separating beyond 32 cm dismisses it. The difference between those distances prevents flicker. Loss of tracking hides all new visuals.</p><p>Tests cover real XRTools pickup, XRServer controller discovery, occupied hands, rig replacement, save/reload, older saves, reset and the untouched legacy arrow mode. Native captures use the museum's existing room and lighting. They are not headset recordings.</p><ul>CHECKS</ul><a href="checks.json">Machine-readable evidence and source hashes</a></details>
<details><summary>Implementation and repeatable check</summary><p><code>python tools/run_encounter_probe.py Point_Coordinates --sequence primitives --no-bridges --render --probe tools/probes/first_catalyst.gd --output-tag first-catalyst</code></p><ul>LINKS</ul></details>
</main><footer>The first grabbable point and former red-arrow cue are in Point_Coordinates after the earlier Point One split. The scene order and book texts were not changed in this pass.</footer></html>'''
page = page.replace('COUNT', str(count)).replace('CARDS', cards).replace('CHECKS', checks).replace('LINKS', links)
(OUT / 'index.html').write_text(page, encoding='utf-8')
print(f'Published {count} passing checks and {len(images)} native captures: {OUT / "index.html"}')
