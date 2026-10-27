"""Publish the reviewed brittle posture and its explicit input/model limits."""
from pathlib import Path
import json,shutil,hashlib
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'ada_run/leaning-brittle';NATIVE=ROOT/'ada_run/matter-reference';REVIEW=ROOT/'doc/ports/2026-10-25-leaning-brittle';GALLERY=ROOT/'doc/book/iterations/2026-10-25-leaning-brittle'
read=lambda p:json.loads(p.read_text(encoding='utf-8'))
paths={'physics':NATIVE/'leaning-brittle-physics-checks.json','player':NATIVE/'leaning-brittle-player-checks.json','capture':NATIVE/'leaning-brittle-capture-checks.json','save':OUT/'save-checks.json','export':OUT/'export.json','editor':OUT/'editor-checks.json'}
reports={key:read(path) for key,path in paths.items()};assert all(report['passed'] for report in reports.values())
REVIEW.mkdir(parents=True,exist_ok=True);GALLERY.mkdir(parents=True,exist_ok=True)
for name in ['leaning-brittle-before','leaning-brittle-moving','leaning-brittle-after','leaning-brittle-player-before','leaning-brittle-player-after']:shutil.copy2(NATIVE/(name+'.png'),GALLERY/(name+'.png'))
for key,path in paths.items():shutil.copy2(path,REVIEW/(key+'-checks.json'))
sources=['commons/artifacts/matter_experiments/leaning_together.gd','commons/artifacts/matter_experiments/leaning_piece.gd','commons/artifacts/registry/matter_experiments.json','commons/void/rooms.json']
status=dict(completed=True,floor=46,posture='brittle',loose_parts=6,editable_members=reports['editor']['parts'],native_meshes=reports['editor']['meshes'],physics_checks=len(reports['physics']['checks']),player_checks=len(reports['player']['checks']),physical_headset_tested=False,source_sha256={name:hashlib.sha256((ROOT/name).read_bytes()).hexdigest() for name in sources})
(REVIEW/'STATUS.json').write_text(json.dumps(status,indent=2)+'\n',encoding='utf-8')
(REVIEW/'REVIEW.md').write_text(f'''# Leaning Together / brittle posture

The user asked for gravity and a precarious arrangement that holds untouched and falls apart when disturbed. Floor 46 retains all eight other installations, the same work-area position/facing/scale, and all other floor arrangements. The selected config explicitly sets `brittle: true`; any authored member overrides are preserved.

## What changed

- The same 1.25 × 0.07 × 0.26 m planks stand on their 70 mm edges. Both chocks bear near their edges with a nominal 8 mm depth overlap.
- The outlined cube rests above the plank ends, slightly offset toward the approach. The ball remains a loose probe weight in the board tray. It is not a hidden collapse trigger.
- All six parts run native gravity. The frame uses lower contact friction (0.15 for planks/cube); the board remains 0.22 and wooden chocks 0.85. No joints, snap locks, balancing corrections, timer or touch-to-collapse flag.
- A desktop click or VR pointer trigger applies one finite impulse at the actual surface hit: mass × 0.25 m/s along the pointer ray. It is a digital nudge, not a fall animation. Natural XR collision-hand contact can also disturb the frame with the grip released.
- A low physical lip retains the loose ball and fallen parts nearby. The ball has native damping and may sleep once at rest; it is never frozen during play. Reset releases held parts, restores authored poses, zeroes their velocities and returns them to gravity.

## Evidence and limits

{status['physics_checks']} native checks passed: 30 seconds untouched at three rotations and negative elevation, all six gravity bodies, ball retained by real geometry, actual ray-surface taps on both planks, cube and both chocks, hover without a tap, fall and reset. The taps dismantled the tested initial arrangement; this is not a claim that every infinitesimal contact or force direction must cause a collapse.

{status['player_checks']} actual main-floor input checks passed: desktop mouse and synthetic XR trigger taps on plank/cube/chock, a physical ungripped synthetic XR collision-hand nudge, ball pickup and held reset. The physical hand case generates no pointer-tap signal. Physical headset testing remains.

{status['editable_members']} authoring members / {status['native_meshes']} native meshes. Production editor move/rotate/copy/save validation and desktop/VR mirror parity passed without saving test edits. The whole work area and each of its ten members remain editable. Arbitrary authoring edits may remove the precarious starting contacts.

The editor preview deliberately resets/freezes only its export copy. Gravity runs in Godot desktop/VR, not in the static Three.js lab-editor layout preview. Runtime hand arrangements are temporary; save starting arrangements in the editor. Native grabbed bodies follow kinematic hands, without biological compliance or haptic force.

Photographs show the real registered floor after 15 untouched seconds, during a probe-pointer tap and after collapse. Those inspection cameras hide neighbouring storeys. Separate before/after images come from the actual desktop-input test. Source fingerprints and all six receipts are alongside this review. Earlier braced-posture receipts remain historical.

Gallery: http://localhost:3003/book-review/doc/book/iterations/2026-10-25-leaning-brittle/index.html
Editor: http://localhost:3003/lab-editor?mode=void&floor=46
''',encoding='utf-8')
editor_photo='''<figure><img loading="lazy" src="leaning-brittle-editor.jpg" alt="The brittle posture selected in the saved live editor"><figcaption>The lab editor shows the authored start. Gravity and touch run in Godot.</figcaption></figure>''' if (GALLERY/'leaning-brittle-editor.jpg').exists() else ''
html='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Leaning Together / a brittle balance</title><style>
*{box-sizing:border-box}body{margin:0;background:#eee9df;color:#241f28;font:16px/1.55 system-ui,sans-serif}main{max-width:1320px;margin:auto;padding:40px 24px}h1{font-size:clamp(40px,7vw,86px);line-height:1;max-width:1000px}a{color:#7e2150;text-underline-offset:3px}p{max-width:850px}img{display:block;width:100%;height:auto}figure{margin:30px 0}figcaption{font-size:13px;margin-top:8px}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,450px),1fr));gap:24px}.note{border-left:4px solid #bd3a77;padding:14px 20px;background:#e8dce2}
</style><main><p>FLOOR 46 / LEANING TOGETHER / UPDATED POSTURE</p><h1>A brittle balance.<br>Stand. Touch. Come apart.</h1><p>The planks stand on their narrow edges, with the cube above and the chocks barely overlapping their feet. All six loose parts have gravity. The ball waits on the tray as a test weight.</p>
<p><a href="/lab-editor?mode=void&floor=46">Open the saved floor in the editor ↗</a> · <a href="/book-review/doc/book/iterations/2026-10-25-leaning-together/index.html">Earlier braced study ↗</a></p>
<p class="note"><strong>Gravity runs in the Godot game.</strong> The lab editor keeps a static preview so you can arrange the parts. In desktop play, left-click a part for a light tap; right-click to hold/release. In VR, touch with a hand, grip a part, or use a pointer tap.</p>
<figure><img src="leaning-brittle-before.png" alt="Narrow-edge timber frame supporting an ivory cube under live gravity"><figcaption>Untouched: the live initial arrangement holds. Thirty-second idle checks passed at three rotations.</figcaption></figure>
<div class="grid"><figure><img src="leaning-brittle-moving.png" alt="The timber frame beginning to change after a finite tap"><figcaption>A small finite impulse at the actual surface starts the movement.</figcaption></figure><figure><img src="leaning-brittle-after.png" alt="The two planks and cube after the contact-driven collapse"><figcaption>The aftermath is Jolt contact and gravity. There is no scripted release or collapse animation.</figcaption></figure></div>
<p>Both planks, the cube and either foot chock dismantled the tested starting arrangement when nudged from the approach. Hovering alone changes nothing. Different touches and different hand-built arrangements can produce different outcomes.</p>
<p>Reset restores the authored arrangement with gravity live. All ten members remain editable. The ball and any detached pieces are physical objects; the low tray lip keeps them nearby. Runtime hand placement is temporary; save starting layouts in the editor.</p>
<div class="grid"><figure><img loading="lazy" src="leaning-brittle-player-before.png" alt="Actual desktop player view before a mouse tap"><figcaption>Actual desktop input: before.</figcaption></figure><figure><img loading="lazy" src="leaning-brittle-player-after.png" alt="Actual desktop player view after a mouse tap"><figcaption>Actual desktop input: after.</figcaption></figure></div>'''+editor_photo+'''<p>Mouse controls, synthetic XR trigger and physical collision-hand touch, grab/reset and editor validation passed. Physical headset testing remains. Inspection views hide neighbouring storeys; their tap uses an explicit probe pointer.</p></main></html>'''
(GALLERY/'index.html').write_text(html,encoding='utf-8')
previous=ROOT/'doc/book/iterations/2026-10-25-leaning-together/index.html'
old=previous.read_text(encoding='utf-8')
if 'data-brittle-update' not in old:
    old=old.replace('<main>','<main><p data-brittle-update class="note"><strong>Updated:</strong> <a href="/book-review/doc/book/iterations/2026-10-25-leaning-brittle/index.html">Open the new brittle posture and before/after screenshots ↗</a>. The earlier braced study is recorded below.</p>',1);previous.write_text(old,encoding='utf-8')
print(json.dumps({key:value for key,value in status.items() if key!='source_sha256'}))
