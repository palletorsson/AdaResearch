"""Publish the current hand-tools pass and an explicitly proposed tutorial route."""
from pathlib import Path
import hashlib
import html
import json
import shutil

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-07-forces-stick-hinges-and-catalyst'
OUT.mkdir(parents=True, exist_ok=True)
for source, target in [('ada_run/forces_hand_tools.json', 'hand-tests.json'),
                       ('ada_run/force_play_models.json', 'model-tests.json'),
                       ('doc/book/course/forces-tutorial-carriers.md', 'tutorial-carriers.md')]:
    shutil.copy2(ROOT/source, OUT/target)
reports = [OUT/'hand-tests.json', OUT/'model-tests.json'] + sorted((OUT/'museum').glob('*/report.json'))
tests = [json.loads(p.read_text(encoding='utf-8-sig')) for p in reports]
assert all(t['passed'] for t in tests), 'Do not publish failed checks as passing.'
count = sum(len(t['checks']) for t in tests)
plan = (OUT/'tutorial-carriers.md').read_text(encoding='utf-8')
rows = []
for line in plan.splitlines():
    if not line.startswith('|') or line.startswith('|---'): continue
    cells = [html.escape(c.strip()) for c in line.strip('|').split('|')]
    tag = 'th' if not rows else 'td'
    rows.append('<tr>'+''.join(f'<{tag}>{c}</{tag}>' for c in cells)+'</tr>')

def picture(path, caption):
    assert (OUT/path).is_file(), path
    return f'<figure><a href="{path}"><img loading="lazy" src="{path}" alt="{html.escape(caption)}"></a><figcaption>{caption}</figcaption></figure>'

spring = 'museum/Vectors_Act4b_Oscillation/'
resistance = 'museum/Vectors_Act4a_KineticForces/'
gallery = picture(spring+'take-the-stick.png', 'A 2.2 metre stick, rose grip and local RETURN STICK. Actual museum capture.')
gallery += picture(spring+'swings-in-motion.png', 'Push the seat or pull its rose grip. The hinge continues to own the attachment.')
gallery += picture(resistance+'basin-ramps.png', 'Four matching receiving basins: the incline, runoff and retained objects can be read together.')
gallery += picture(resistance+'basin-trails.png', 'After release: the bodies leave real motion trails and stay in their lanes.')
gallery += picture(spring+'catalyst.png', 'The existing catalyst returns in Forces mode: slow a moving body and temporarily add damping.')
gallery += picture(spring+'spring-points.png', 'The same point is the proposed tutorial carrier. Begin with one spring before coupling the row.')

page = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Forces — push, release, keep the attachment</title><style>
*{box-sizing:border-box}body{margin:0;background:#efede6;color:#23252a;font:17px/1.6 system-ui,sans-serif}main{max-width:1240px;margin:auto;padding:40px 24px}header{max-width:820px;margin-bottom:40px}h1{font:clamp(34px,5vw,64px)/1.1 Georgia,serif}h2{font:32px Georgia,serif;margin-top:52px}p{max-width:840px}a{color:#783650}nav{display:flex;gap:22px;flex-wrap:wrap}figure{margin:0 0 36px}img{width:100%;display:block;border-radius:5px}figcaption{padding:12px 0;max-width:850px;color:#50525a}.table{overflow-x:auto}table{border-collapse:collapse;width:100%;font-size:15px}th,td{text-align:left;vertical-align:top;padding:16px;border-bottom:1px solid #c4c1b7}th{background:#ddd9cf}td:nth-child(2){font-weight:650;min-width:180px}td:first-child{min-width:145px}.note{background:#e0d5da;padding:20px;border-left:4px solid #98617c}footer{margin:50px 0;font-size:14px;color:#555}li{margin:8px 0}@media print{nav{display:none}figure{break-inside:avoid}main{padding:0}}
</style><main><header><p>ENDLESS MUSEUM · FORCES · 7 OCTOBER 2026</p><h1>Push, release,<br>keep the attachment.</h1><p>The point carries the lesson. A stick lets us reach and disturb it. The catalyst lets us intervene after motion has begun.</p><nav><a href="#museum">Inside the museum</a><a href="#tutorial">One object per hall</a><a href="#evidence">Tests</a><a href="tutorial-carriers.md">Download the editable proposal</a></nav></header>
<section class="note"><strong>Implemented in the existing halls</strong><ul><li>Long physical pushing sticks beside springs, swings, constraints, torque and friction; each has a local return button.</li><li>Jointed bodies refuse direct pickup. Rose grips apply forces, while hinges and pins retain their anchors.</li><li>Dark receiving basins surround the four existing friction ramps.</li><li>The existing catalyst is offered in Motion, Oscillation and Arena. Its Forces mode slows bodies and temporarily adds damping.</li></ul><p>Restart or reload the museum to build the updated encounters. The table below is a tutorial proposal; full tutorial.md and final.md have not been rewritten.</p></section>
<h2 id="museum">Inside the museum</h2>'''+gallery+'''
<h2 id="tutorial">Which object carries each lesson?</h2><p>Preserve the sphere's identity wherever it helps. Give it a new relation or ability, then let the supporting artifacts test that understanding. A museum object does not automatically become another programming assignment.</p><div class="table"><table>'''+''.join(rows)+'''</table></div>
<p><strong>First pilot: the tethered point.</strong> Pull it, release it, change damping, compare a hinged seat, then disturb or settle the motion with the available tools. The tutorial reconstructs the spring response; the whole room remains open for play.</p>
<p>The current full catalyst is a separate existing implementation, BecomingCatalyst. The learner's PointBody can carry the conceptual lineage without inheriting its complete editor and mode system. Choreography's conveyor is a proposed focus change; the current main placement remains the phase rods.</p>
<h2 id="evidence">What was checked</h2><p><strong>'''+str(count)+''' recorded checks passed.</strong> Tests exercised actual Jolt joints, real XRTools grabs with supplied controller movements, desktop carry, stick contact, catalyst projectile contact, repeated damping/restoration, slope comparisons and routes through the affected museum halls. Physical headset reach and comfort, and Quest performance, remain unverified.</p><p>In the pull test the hinge drift stayed below 1 cm. No script errors were reported in the final runs. The reused full catalyst scene logs two unassigned ViewportTexture diagnostics on loading; its visible pedestal, configured mode and projectile effect pass the checks, but its separate wrist editor panels are outside this verification. Existing project UID and legacy solver warnings also remain.</p><nav><a href="hand-tests.json">Hand and catalyst assertions</a><a href="model-tests.json">Five encounter regressions</a><a href="verification.json">Source hashes and hall evidence</a></nav>
<footer>Actual Godot museum captures. The tutorial candidate list is an editable proposal, not a claim that the full book has caught up with the museum.</footer></main></html>'''
(OUT/'index.html').write_text(page, encoding='utf-8')
sources = ['commons/artifacts/force_play/play_space.gd','commons/artifacts/force_play/encounter.gd',
           'commons/artifacts/force_play/push_stick.gd','commons/artifacts/force_play/push_stick_rack.gd',
           'commons/scenes/DesktopInteractionPointer.gd','commons/artifacts/force_halls/hall_display.gd',
           'commons/hazards/becoming_catalyst/modes/forces_projectile.gd',
           'tools/probes/forces_hand_tools.gd','tools/probes/forces_hands_museum.gd',
           'doc/book/course/forces-tutorial-carriers.md']
(OUT/'verification.json').write_text(json.dumps({'passed': True,'checks':count,'reports':[str(p.relative_to(OUT)).replace('\\','/') for p in reports],
    'sources':{p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in sources}},indent=2),encoding='utf-8')
print(OUT/'index.html', count, 'checks')
