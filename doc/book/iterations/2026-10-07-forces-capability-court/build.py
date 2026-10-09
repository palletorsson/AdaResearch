"""Publish verified captures of the production museum, with a bounded claim of completion."""
from pathlib import Path
import hashlib
import html
import json
import shutil
from html.parser import HTMLParser
from urllib.parse import unquote

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
RUN = ROOT / 'ada_run/encounter_pilot/Vectors_Act5_ForceAsPlace'
report = json.loads((RUN/'report.json').read_text(encoding='utf-8'))
assert report['passed'], report['failures']
log = (RUN/'stdout.log').read_text(encoding='utf-8', errors='replace')
assert 'SCRIPT ERROR' not in log, 'Resolve script errors before publishing'
images = [
    ('court-entry','A court inside the Endless Museum','The existing field encounter opens into a trial court. The ball, cube, slope and moving platform acquire new relations. Walk around each station; no outcome is compulsory.'),
    ('thrust-points','The point moves you','The same 28 cm point body is still grabbable. Its trigger now adds thrust opposite your aim. Two held points lift the XR rig. Release stops acceleration from the points, while gravity and existing velocity continue.'),
    ('donut-cake','The donut cake mortar','An eight-tier base, resolutions 4 through 11, supports an adjustable launcher. Lower, fire, raise: one launch speed, several trajectories. The emitted objects are physical torus rings with open collision holes.'),
    ('rings-and-posts','A miss stays in the room','The target posts can receive a ring, but the same collision rules can tip, stack or scatter it. Eight rings are available. A missed ring can be picked up and used; firing does not silently erase earlier attempts.'),
    ('launch-and-platform','A familiar platform becomes a destination','Step onto the launch pad. It gives an upward and forward velocity; the earlier moving cube crosses the landing path. Timing changes the encounter, even when the launch stays the same.'),
    ('hinge-aftermath','A pole becomes a bridge','Pressing RELEASE POLE removes its hold. Gravity turns the rigid body around an actual hinge. The receiving block arrests its fall. The image shows the resulting bridge, not a prescribed animation.'),
    ('spring-points','One push reaches another body','The same point body appears twice on a rail. A restoring force pulls each toward its own resting position; their collision transfers motion. Pull a point or press the impulse button and observe the other one.'),
    ('drag-and-destination','Drag, then arrival','Five familiar cubes share a drag lane and slope. Switch the drag coefficient and compare equal pushes. Bring the unpowered point from the entrance to the final plinth; the other objects keep their altered positions.')
]
(HERE/'images').mkdir(exist_ok=True)
for stem, _, _ in images:
    shutil.copy2(RUN/f'{stem}.png',HERE/'images'/f'{stem}.png')
shutil.copy2(RUN/'report.json',HERE/'runtime-checks.json')
shutil.copy2(RUN/'stdout.log',HERE/'engine.log')
count = len(report['checks'])
observed = report['observations']
cards = ''.join(f'<section id="{stem}"><h2>{html.escape(title)}</h2><a href="images/{stem}.png"><img loading="lazy" src="images/{stem}.png" alt="{html.escape(title)} — captured in Godot"></a><p>{html.escape(caption)}</p></section>' for stem,title,caption in images)
checks = ''.join(f'<li>{html.escape(c["name"])}</li>' for c in report['checks'])
page = f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>The point gains power — built in the museum</title>
<style>body{{margin:0;background:#eeece5;color:#24262b;font:18px/1.6 system-ui,sans-serif}}main{{max-width:1180px;margin:auto;padding:40px 24px 100px}}header{{max-width:850px;padding:30px 0}}h1{{font:clamp(42px,6vw,78px)/1.04 Georgia,serif;margin:15px 0 28px}}h2{{font:32px/1.2 Georgia,serif}}p{{max-width:850px}}.kicker{{font-size:13px;text-transform:uppercase;letter-spacing:.15em;color:#765769}}nav{{display:flex;flex-wrap:wrap;gap:12px;margin:30px 0}}a{{color:#744b65}}nav a,.tag{{background:#e0d5db;padding:7px 12px;border-radius:3px;font-size:14px}}img{{width:100%;height:auto;display:block;border-radius:3px}}section{{margin:60px 0}}.note{{padding:24px 30px;background:#e2ded4;border-left:4px solid #9c6685}}table{{border-collapse:collapse;width:100%;font-size:16px}}td,th{{padding:12px;text-align:left;vertical-align:top;border-bottom:1px solid #c9c4b9}}code{{font-size:.88em;overflow-wrap:anywhere}}details{{background:#e5e1d8;padding:20px}}summary{{cursor:pointer}}li{{margin:5px 0}}@media print{{nav{{display:none}}section{{break-inside:avoid}}details{{display:none}}}}</style>
<main><header><div class="kicker">Endless Museum · Forces · 7 October 2026 · playable first pass</div><h1>The point gains power.</h1><p>The familiar bodies now meet in one physical court: thrust points, a cake mortar, a launch pad, a moving destination, a falling pole, springs and drag. A simple intention meets the motion already in the room.</p><span class="tag">{count}/{count} runtime checks passed</span> <span class="tag">Images from the actual museum</span></header>
<nav><a href="#visit">Try it</a><a href="#court-entry">The room</a><a href="#donut-cake">Mortar</a><a href="#hinge-aftermath">Hinge</a><a href="#drag">On drag</a><a href="#evidence">Evidence</a><a href="../2026-10-07-forces-thirty-upgrades/illustrations.html#plate-10">Illustrated proposal</a></nav>
<div class="note"><strong>Built scope.</strong> This court extends <code>Vectors_Act5_ForceAsPlace</code>, the last of the thirteen Forces halls. The original local field and crossing remain. This implements a first combined trial from the proposal; it does not claim that all thirty ideas, enemies or a new vortex are finished. Tutorial and final manuscripts have not been rewritten in this pass.</div>
<section id="visit"><h2>Enter the court</h2><p>In Godot, open <a href="../../../../commons/scenes/force_capability_museum.tscn"><code>commons/scenes/force_capability_museum.tscn</code></a> and run that scene with F6. It opens the real Endless Museum at the last Forces hall. Continue past the field crossing. The same court is now in the ordinary Forces route, before Form Finding.</p><table><tr><th>VR</th><td>Grip a black point in each hand. Aim the controllers down/back and hold the triggers. Press the stations’ physical buttons to release the pole, excite a spring, change drag or fire the mortar.</td></tr><tr><th>Desktop</th><td>WASD moves. Right mouse grabs/releases a point; left mouse holds its action. Aim down to rise, backward to travel forward. Click station buttons. A single point also supplies a gentle lift.</td></tr><tr><th>Trial</th><td>Carry the third, unpowered point from the entrance to the final plinth. Use the other bodies however you choose. A successful delivery changes the readout.</td></tr><tr><th>Reset</th><td>Misses remain until RESET TRIAL. Put held objects down first. Only bodies lost far outside the room are recovered automatically. State lasts while the streamed hall stays loaded.</td></tr></table></section>
{cards}
<section id="drag"><h2>To drag</h2><p>You drag something with you. The medium exerts drag against its motion. Drag performance introduces another relation between a body and the forms available to it. These meanings touch without becoming the same explanation.</p><p>The mechanical question is precise: what force acts, in what direction, on which body? The reflective question stays open: what must a body carry, what resists it, and which capacities become possible when we change its presentation or attachments? The room gives those questions actions and consequences.</p></section>
<section id="evidence"><h2>What the run establishes</h2><p><strong>{count} checks passed</strong> in the production museum. The probe used real rigid bodies and collisions, the production desktop grab/action/drop path, and an actual XRTools player rig with two pickup functions. It supplied input; no physical headset was worn.</p><p>Measured launch rise: <strong>{observed['launch_height_gain']:.2f} m</strong> during the test. XR lift: <strong>{observed['xr_lift_metres']:.2f} m</strong>. In the matched cube trial, travel changed from <strong>{observed['drag_distances'][0]:.2f} m</strong> to <strong>{observed['drag_distances'][1]:.2f} m</strong> when drag was enabled. These are run observations, not general performance guarantees.</p><p>Headset reach, comfort and Quest frame time remain to be checked in VR. The engine emits one existing unresolved-UID diagnostic (<code>rwex60pqapc</code>); this run has no script errors. The successful tests do not certify the whole project.</p><p><a href="runtime-checks.json">Runtime report</a> · <a href="engine.log">Engine log</a> · <a href="../../../../commons/artifacts/force_capability_lab/README.md">Controls, lineage and model boundaries</a> · <a href="before/map_data.json">Map before this pass</a></p><details><summary>Read the individual checks</summary><ul>{checks}</ul></details></section>
</main></html>'''
(HERE/'index.html').write_text(page,encoding='utf-8')
source_paths = [ROOT/'commons/maps/Vectors_Act5_ForceAsPlace/map_data.json', ROOT/'commons/artifacts/registry/force_capability_lab.json', ROOT/'commons/scenes/force_capability_museum.tscn', ROOT/'tools/probes/force_capability_lab.gd']
source_paths += list((ROOT/'commons/artifacts/force_capability_lab').glob('*.gd'))
manifest = {str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in source_paths}
(HERE/'source-hashes.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
class Links(HTMLParser):
    def __init__(self): super().__init__(); self.refs=[]; self.ids=set()
    def handle_starttag(self,tag,attrs):
        attrs=dict(attrs)
        if 'id' in attrs: self.ids.add(attrs['id'])
        self.refs.extend(attrs[k] for k in ('href','src') if k in attrs)
links=Links(); links.feed(page)
for ref in links.refs:
    if ref.startswith('#'): assert ref[1:] in links.ids, ref
    else: assert (HERE/unquote(ref.split('#')[0])).resolve().exists(), ref
before=json.loads((HERE/'before/map_data.json').read_text(encoding='utf-8'))
after=json.loads((ROOT/'commons/maps/Vectors_Act5_ForceAsPlace/map_data.json').read_text(encoding='utf-8'))
changes=[]
for kind,rows in after['layers'].items():
    assert len(rows)==50 and all(len(row)==16 for row in rows),kind
    for z in range(24):
        for x in range(16):
            if rows[z][x]!=before['layers'][kind][z][x]: changes.append([kind,x,z])
assert changes==[['structure',8,20],['utilities',8,20]], changes
(HERE/'validation.json').write_text(json.dumps({'runtime_checks':count,'passed':True,'images':len(images),'local_references':len(links.refs),'original_layer_edits':changes,'meaning':'Former exit moved to annex; field and prior artifacts retained.'},indent=2)+'\n',encoding='utf-8')
print(f'Published {len(images)} real museum captures; {count} passing checks.')
