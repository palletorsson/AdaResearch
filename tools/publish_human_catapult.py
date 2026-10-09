"""Publish the verified human-catapult repair and real museum captures."""
from pathlib import Path
import hashlib
import html
import json
import shutil

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-07-human-catapult-launch'
for src, dst in [('ada_run/human_catapult_launch_tests.json', 'physics-tests.json'),
                 ('ada_run/human_catapult_launch_tests.log', 'physics-tests.log'),
                 ('commons/artifacts/human_catapult/LAUNCH.md', 'artifact-notes.md')]:
    shutil.copy2(ROOT/src, OUT/dst)
tests = [json.loads((OUT/p).read_text(encoding='utf-8-sig'))
         for p in ['physics-tests.json', 'museum/report.json']]
assert all(t['passed'] and all(c['passed'] for c in t['checks']) for t in tests)
assert all('SCRIPT ERROR' not in (OUT/p).read_text(encoding='utf8', errors='replace')
           for p in ['physics-tests.log', 'museum/engine.log'])
count = sum(len(t['checks']) for t in tests)
flight = tests[1]['observations']['catapult']

def figure(name, caption):
    path = f'museum/{name}.png'
    assert (OUT/path).is_file()
    return f'<figure><a href="{path}"><img src="{path}" alt="{html.escape(caption, quote=True)}"></a><figcaption>{caption}</figcaption></figure>'

page = '''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Human catapult — 3, 2, 1</title><style>
*{box-sizing:border-box}body{margin:0;background:#171c24;color:#eee9df;font:17px/1.65 system-ui,sans-serif}main{max-width:1200px;margin:auto;padding:40px 24px 70px}h1{font:clamp(42px,6vw,76px)/1.05 Georgia,serif;margin:24px 0}h2{font:32px/1.2 Georgia,serif;margin-top:42px}p{max-width:840px}a{color:#ff9793}nav{display:flex;gap:22px;flex-wrap:wrap;margin:26px 0}.entry{padding:18px 26px;background:#30303b;border-left:5px solid #ff544d}.kicker{font-size:13px;letter-spacing:.14em;text-transform:uppercase}figure{margin:30px 0}img{width:100%;height:auto;display:block}figcaption{color:#bdbec8;margin-top:10px;max-width:900px}li{margin:10px 0}@media print{body{background:white;color:black}nav{display:none}figure{break-inside:avoid}}
</style></head><body><main><p class="kicker">Endless Museum · Forces · 7 October 2026</p><h1>Human catapult<br>3, 2, 1</h1><p>The basket now recognises the player, counts down and launches them over the throwing arm. A solid red arc shows the same launch velocity and gravity that move the player.</p>
<nav><a href="#museum">Inside the museum</a><a href="#repair">What changed</a><a href="#checks">Checks</a><a href="artifact-notes.md">Implementation notes</a></nav>
<div class="entry"><strong>Reload the museum and return to Human Catapult in the Launch hall.</strong><p>Set angle and speed, walk up the ramp into the basket, then wait for 3–2–1. Step out during the countdown to cancel. The launch goes forward over the axle. Your view remains upright.</p></div>
<h2 id="museum">The path now points where you fly</h2>'''
page += figure('countdown', 'Inside the real launch hall: an open boarding entrance, the button beside the basket, a visible countdown and the red flight path.')
page += figure('red-trajectory', 'An elevated museum view shows the corrected arc travelling over the arm into the open landing space.')
page += '''<h2 id="repair">What was stopping it</h2><ul>
<li>The basket detector recognised XR bodies but missed the museum’s desktop player. It now checks both, with actual feet inside the boarding area.</li>
<li>The FIRE button’s physical collider blocked the entrance. It now sits beside the basket; the cup has a clear front and an overlapping access ramp.</li>
<li>The old direction pointed back toward boarding. The launch now points over the axle. Preview and release share one world-space velocity, including when the catapult is rotated.</li>
<li>The launch uses the museum’s desktop and XR movement owners. The basket floor clears during release, and the red path stays at the release position while the arm swings.</li>
</ul><p>The swing is a release animation. The actual flight is a velocity handoff followed by gravity and collisions. The red line predicts an unobstructed flight; another object can interrupt it.</p>'''
page += f'''<h2 id="checks">{count} assertions passed</h2><p>24 physics, XR and adjacent fountain checks; 28 production museum checks. The museum player walked up the ramp without jumping or teleporting into the cup, completed the countdown and travelled {-flight['travel_local'][2]:.1f} metres forward, rising {flight['peak_rise']:.1f} metres. During the first second, measured motion differed from the continuous red prediction by at most {flight['preview_error']*100:.1f} cm, consistent with discrete physics steps.</p>
<p>The tests also cover 0°, 90° and 180° placements, cancellation, reboarding, one launch per countdown, actual XR body and origin movement, and unchanged tracked-head pose. Physical headset comfort remains untested.</p>
<p>The museum run also exposed an empty-trail mesh error in the neighbouring firework fountain. Its rendering now handles a finished flight with no visible segments and resumes trails on the next one.</p>
<nav><a href="physics-tests.json">Physics and XR assertions</a><a href="museum/report.json">Museum assertions</a><a href="verification.json">Source hashes</a><a href="physics-tests.log">Physics log</a><a href="museum/engine.log">Museum log</a></nav>
<p>All pictures are actual museum renders. Existing unknown-UID, ignored Jolt solver-bias and compatibility-renderer diagnostics remain in the logs. No script errors occurred in the final runs.</p></main></body></html>'''
(OUT/'index.html').write_text(page, encoding='utf8')
sources = ['commons/artifacts/human_catapult/human_catapult.gd',
           'commons/artifacts/human_catapult/human_catapult.tscn',
           'commons/artifacts/registry/human_catapult.json',
           'commons/artifacts/firework_burst/live_fountain.gd',
           'tools/probes/human_catapult_launch.gd',
           'tools/probes/human_catapult_museum.gd',
           'tools/probes/forces_selection_models.gd']
(OUT/'verification.json').write_text(json.dumps({'passed': True, 'checks': count,
    'source_hashes_at_publication': {p: hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in sources}}, indent=2), encoding='utf8')
print(OUT/'index.html', count, 'checks')
