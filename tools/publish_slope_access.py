"""Publish actual museum captures and bounded scope for the slope access fix."""
from pathlib import Path
import hashlib
import json
import shutil

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-07-slopes-walk-up-and-drop'
OUT.mkdir(parents=True, exist_ok=True)
shutil.copy2(ROOT/'ada_run/slope_access_and_drops.json', OUT/'drop-tests.json')
shutil.copy2(ROOT/'doc/book/iterations/2026-10-07-forces-stick-hinges-and-catalyst/museum/Vectors_Act4a_KineticForces/basin-ramps.png', OUT/'before.png')
reports = [OUT/'drop-tests.json', OUT/'museum/report.json']
tests = [json.loads(p.read_text(encoding='utf-8-sig')) for p in reports]
assert all(t['passed'] for t in tests)
count = sum(len(t['checks']) for t in tests)
assert 'SCRIPT ERROR' not in (OUT/'museum/engine.log').read_text(encoding='utf8', errors='replace')

def figure(path, caption):
    assert (OUT/path).is_file()
    return f'<figure><a href="{path}"><img src="{path}" alt="{caption}" loading="lazy"></a><figcaption>{caption}</figcaption></figure>'

page = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Slopes — walk up and watch a body fall</title><style>
*{box-sizing:border-box}body{margin:0;background:#eeeae2;color:#24242a;font:17px/1.6 system-ui,sans-serif}main{max-width:1240px;margin:auto;padding:40px 24px}h1{font:clamp(36px,5vw,66px)/1.08 Georgia,serif;max-width:900px}h2{font:32px Georgia,serif;margin-top:44px}p{max-width:830px}a{color:#78334f}figure{margin:30px 0}img{width:100%;display:block;border-radius:4px}figcaption{padding-top:10px;color:#555;max-width:880px}.note{padding:18px 24px;background:#dfd3d8;border-left:4px solid #b65f85}nav{display:flex;flex-wrap:wrap;gap:20px}li{margin-bottom:8px}
</style><main><p>ENDLESS MUSEUM · FORCES · 7 OCTOBER 2026</p><h1>Walk up.<br>Watch a body fall.</h1><p>The four comparison lanes now have a physical access ramp and an upper walkway. A single body drops every seven seconds, cycling through smooth cube, smooth ball, rough cube and rough ball.</p>
<nav><a href="#museum">Inside the museum</a><a href="#before">Before</a><a href="#checks">Verification</a></nav>
<div class="note"><p><strong>Reload the museum to get the new geometry.</strong> In the Resistance hall, follow the rose arrow beside the slope basins. Walk up the side ramp, then across the platform to inspect any lane. You can step from the platform directly onto a slope.</p><p>The four bodies are reused, so each lane returns every 28 seconds when none is held. A held body is skipped. AUTO / PAUSE is on the upper walkway beside RELEASE and RESET. RESET followed by RELEASE gives the original simultaneous comparison.</p></div><h2 id="museum">Inside the museum</h2>'''
page += figure('museum/walk-up.png', 'From the museum floor: a marked approach and a gentle ramp with rose rails.')
page += figure('museum/at-the-bodies.png', 'Standing on the upper walkway after physically walking up. The bodies are now below eye level.')
page += figure('museum/a-body-drops.png', 'One of the existing comparison bodies drops onto its slope. Gravity and contact determine what happens next.')
page += figure('museum/access-overview.png', 'The walkway connects all four lanes. The surrounding museum aisle remains clear.')
page += '<h2 id="before">Before</h2>'
page += figure('before.png', 'The previous basin arrangement had raised lane starts but no continuous walking route to them.')
page += f'''<h2 id="checks">Verification</h2><p><strong>{count} checks passed.</strong> Actual Jolt bodies: seven-second cadence, lane rotation, gravity, bounded body count, held-body protection, pause/resume, reset during a pending drop and the original friction comparison. In the actual museum, a standing collision capsule walked from floor to deck, across the four lanes, onto a slope and back down without jumping or teleporting. The hall aisle and exit were also checked.</p><p>These are engine and simulated locomotion checks. Physical headset comfort and Quest performance still need a VR visit. The logs retain the existing unknown UID and legacy Jolt solver-bias warnings.</p><nav><a href="drop-tests.json">Drop assertions</a><a href="museum/report.json">Museum walk assertions</a><a href="verification.json">Source hashes</a><a href="../2026-10-07-forces-stick-hinges-and-catalyst/index.html#tutorial">Tutorial carrier proposal</a></nav><p>Actual Godot museum captures. The hall order and tutorial subjects are unchanged.</p></main></html>'''
(OUT/'index.html').write_text(page, encoding='utf8')
sources = ['commons/artifacts/force_play/encounter.gd', 'tools/probes/slope_access_and_drops.gd', 'tools/probes/slope_access_museum.gd']
(OUT/'verification.json').write_text(json.dumps({'passed':True,'checks':count,'sources':{p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in sources}}, indent=2), encoding='utf8')
print(OUT/'index.html', count, 'checks')
