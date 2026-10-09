"""Publish the club and punching bag with actual museum images and checks."""
from pathlib import Path
import hashlib
import html
import json
import shutil

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-07-club-and-punching-bag'
for src,dst in [('ada_run/force_impact_tools.json','physics-tests.json'),
                ('ada_run/force_impact_tools.log','physics-tests.log'),
                ('ada_run/forces_hand_tools.json','rack-regression.json'),
                ('ada_run/force_hand_tools_rack_regression.log','rack-regression.log'),
                ('commons/artifacts/force_play/IMPACT_TOOLS.md','artifact-notes.md')]:
    shutil.copy2(ROOT/src,OUT/dst)
tests=[json.loads((OUT/p).read_text(encoding='utf-8-sig')) for p in ['physics-tests.json','rack-regression.json','museum/report.json']]
assert all(t['passed'] and not t['failures'] for t in tests)
assert all('SCRIPT ERROR' not in (OUT/p).read_text(encoding='utf8',errors='replace') for p in ['physics-tests.log','rack-regression.log','museum/engine.log'])
count=sum(len(t['checks']) for t in tests)
impact=tests[2]['observations']['impacts']

def figure(name,caption):
    path=f'museum/{name}.png'
    assert (OUT/path).is_file()
    return f'<figure><a href="{path}"><img src="{path}" alt="{html.escape(caption,quote=True)}" loading="lazy"></a><figcaption>{caption}</figcaption></figure>'

page='''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Swing the club. The bag comes back.</title><style>
*{box-sizing:border-box}body{margin:0;background:#161c24;color:#eee9df;font:17px/1.65 system-ui,sans-serif}main{max-width:1200px;margin:auto;padding:38px 24px 70px}h1{font:clamp(44px,6vw,74px)/1.08 Georgia,serif;margin:24px 0}h2{font:32px/1.2 Georgia,serif;margin-top:44px}p{max-width:840px}a{color:#ef9ac8}nav{display:flex;gap:22px;flex-wrap:wrap;margin:28px 0}figure{margin:30px 0}img{width:100%;height:auto;display:block}figcaption{color:#bfc0ca;margin-top:10px;max-width:920px}.entry{padding:18px 26px;background:#2f303c;border-left:5px solid #62dbc6}.kicker{font-size:13px;letter-spacing:.14em;text-transform:uppercase}li{margin:8px 0}
</style></head><body><main><p class="kicker">Endless Museum · Forces · 7 October 2026</p><h1>Swing the club.<br>The bag comes back.</h1>
<p>Two new ways to transfer motion: an oversized sci-fi club sends the familiar black sphere onward; a hanging punching bag answers a strike with a swing and a return.</p>
<nav><a href="#club">The club</a><a href="#bag">The bag</a><a href="#checks">Checks</a><a href="artifact-notes.md">Implementation notes</a></nav>
<div class="entry"><strong>Reload the museum. Forces → One push reaches another body.</strong><p>A club waits beside the bowling ball, opposite ROLL. Grab its rose handle and swing. Farther along the hall, the bag stands beside the recoil comparison with another club.</p><p>Punch the bag with your tracked hands, hit it with a tool or pull its rose grip. RETURN CLUB restores an unheld club; RESET restores the bag. Desktop visitors can carry the club or pull the grip.</p></div><h2 id="club">A longer reach, a larger head</h2>'''
page+=figure('club-beside-bowling','The club on its rack beside the existing bowling sphere. Rose grip, metal shaft, broad dark head and mint light details.')
page+=figure('club-sends-the-point','A supplied XR hand swings the held club into the production bowling ball. Contact changes the ball’s motion; no fixed launch command is used.')
page+='<h2 id="bag">Hit, release, watch the return</h2>'
page+=figure('hanging-bag','A seven-kilogram padded body hangs from a real joint. There is room in front and at both sides; the museum’s perimeter route stays clear.')
page+=figure('after-the-punch','The bag swings after contact with a tracked-hand mitt. Its suspension stays attached. The rose grip lets you pull it through force without detaching it.')
page+=f'''<h2 id="checks">{count} assertions passed</h2><p>20 tool and bag checks, 31 production museum checks, and 22 regressions for the existing stick/rack and hand interactions. The actual museum test recorded a bowling-ball speed of {impact['bowling_ball_speed']:.2f} m/s after a slow supplied swing and a bag speed of {impact['bag_speed']:.2f} m/s after a supplied punch. The bag’s joint deviated by less than {impact['bag_joint_error']*1000:.1f} mm during that strike.</p>
<p>Checks cover actual XRTools grabbing, desktop carry, collision while held, dynamic release, refusal to recall a held tool, rack return, bag return under gravity, reset, grip restraint and removal of unused hand mitts. Physical headset feel and Quest frame time remain untested.</p>
<p>Held tools and local hand mitts are kinematic contact sources. The bag is a rigid capsule on a pin joint, with a visual tether; its padding and rope do not deform. These are models of contact and constrained motion, not measurements of a visitor’s muscular force.</p>
<p>The original bowling sphere remains the tutorial carrier. These objects add play around it. Existing hall order, size, aisle and exit remain; full tutorial.md and final.md were not rewritten.</p>
<nav><a href="physics-tests.json">Tool and bag assertions</a><a href="museum/report.json">Museum assertions</a><a href="rack-regression.json">Existing hand-tool regressions</a><a href="verification.json">Source hashes</a><a href="museum/engine.log">Museum log</a></nav>
<p>All pictures are real museum renders. The log retains an existing unknown UID, ignored Jolt solver-bias warnings and two unassigned ViewportTexture diagnostics from the existing catalyst. No script errors occurred in these runs.</p></main></body></html>'''
(OUT/'index.html').write_text(page,encoding='utf8')
sources=['commons/artifacts/force_play/'+p for p in ['impact_club.gd','impact_club.tscn','impact_club_rack.tscn','punching_bag.gd','punching_bag.tscn','push_stick_rack.gd','encounter.gd']]
sources+=['commons/artifacts/registry/force_play.json','commons/artifacts/force_halls/curation.json','commons/maps/VFM_08_Arena/map_data.json','commons/data/museum/em_plan.json','commons/data/museum/em_plan.json','tools/probes/force_impact_tools.gd','tools/probes/force_impact_tools_museum.gd']
(OUT/'verification.json').write_text(json.dumps({'passed':True,'checks':count,'sources':{p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in sources}},indent=2),encoding='utf8')
print(OUT/'index.html',count,'checks')
