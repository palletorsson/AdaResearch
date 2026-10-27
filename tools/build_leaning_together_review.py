"""Package the inspected native views and explicit verification scope."""
from pathlib import Path
import json,shutil
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'ada_run/leaning-together';NATIVE=ROOT/'ada_run/matter-reference'
REVIEW=ROOT/'doc/ports/2026-10-25-leaning-together';GALLERY=ROOT/'doc/book/iterations/2026-10-25-leaning-together'
read=lambda p:json.loads(p.read_text(encoding='utf-8'))
paths={'physics':NATIVE/'leaning-physics-checks.json','player':NATIVE/'leaning-player-checks.json','player_photo':NATIVE/'leaning-player-photo-checks.json','capture':NATIVE/'leaning-capture-checks.json','save':OUT/'save-checks.json','export':OUT/'export.json','editor':OUT/'editor-checks.json'}
reports={key:read(path) for key,path in paths.items()};assert all(report['passed'] for report in reports.values())
REVIEW.mkdir(parents=True,exist_ok=True);GALLERY.mkdir(parents=True,exist_ok=True)
for name in ['leaning-together','leaning-withdrawn','leaning-load','leaning-player']:shutil.copy2(NATIVE/(name+'.png'),GALLERY/(name+'.png'))
for key,path in paths.items():shutil.copy2(path,REVIEW/(key+'-checks.json'))
status=dict(completed=True,floor=46,loose_parts=6,editable_members=reports['editor']['parts'],native_meshes=reports['editor']['meshes'],existing_installations_preserved=8,physics_checks=len(reports['physics']['checks']),player_checks=len(reports['player']['checks']),physical_headset_tested=False)
(REVIEW/'STATUS.json').write_text(json.dumps(status,indent=2)+'\n',encoding='utf-8')
(REVIEW/'REVIEW.md').write_text(f'''# Leaning Together

Completed on floor 46 beside the three friction studies. All eight previous installations and all other saved floors were preserved. No chapter/final.md rewrites.

## The encounter

Two 1.25 m timber planks lean together between two loose wooden chocks. A 0.5 kg outlined ivory cube and a 180 g white ball wait on a 2.8 × 1.5 m board, 0.60 m above the slab. Two timber box plinths carry the board. Pink end marks and a compact reset strip distinguish the loose pieces and controls.

Every one of the six bodies can be picked up and moved. Desktop: right-click to hold/release, wheel to adjust reach, Q/E to roll, Z/X to tilt, Shift+Q/E to yaw. VR: native grip and wrist orientation. Reset releases actual held parts, restores authored member poses, then immediately returns every loose part to gravity. Runtime arrangements last while the scene is loaded; reusable starting arrangements are authored and saved in the lab editor.

## Physical and interaction evidence

- {status['physics_checks']} native contact checks at a rotated negative-floor placement. The planks contact each other and both movable chocks. A held plank remains a support. Withdrawing it lets its neighbour fall; withdrawing a foot chock changes the arrangement. Reset preserves edited member poses.
- {status['player_checks']} actual main-floor player checks: approach and walking around all four sides; desktop mouse and synthetic XR grip pickup, movement and release for all six bodies; all three desktop rotation axes; reset of a held cube. Physical headset testing remains.
- {status['editable_members']} independently editable members and {status['native_meshes']} meshes exported from the registered native scene. Move/rotate/copy pass production validation without saving test edits. Desktop/VR layout mirrors agree.
- Native inspection photographs show the standing arrangement, actual chock withdrawal and a released cube load. Those two interventions use an explicit fixture hand; they are not presented as captured user gestures. The separate player image comes from the actual desktop game.

## What the engine contributes

Jolt integrates gravity, rigid-body contact and friction. There are no joints, planar guides, snap connections, corrective torques, automatic balancing or timed collapses. The board's contact friction is calibrated to 0.22 so the foot chocks matter in the initial arrangement; each plank is 0.8 kg and each chock 1.6 kg. These are chosen toy construction values, not measured timber specimens.

The normal XRTools held-object layer is included in the loose parts' contact masks. A held member is kinematic, as in the native grab system: the hand imposes its pose and can support a posture that cannot persist freely. This does not simulate muscular compliance or haptic force, and large hand movements can pass through other geometry. Loose parts are fully dynamic after release.

The readout reports inclination and time without hands. It has no winning posture or failure flag. The question is relational: what changes when one body, foot or hand moves? Several arrangements are possible; collapse is a physical observation.

## Authoring and limits

Board, two plinths, six loose bodies and controls are independently editable. Arbitrary edits can remove the starting contacts; reset restores the authored layout rather than silently repairing it. Native editor export resets and freezes only its preview copy to capture the authored start; normal gameplay starts live. Existing solver-bias warnings remain; script/runtime errors were not accepted.

Editor: http://localhost:3003/lab-editor?mode=void&floor=46
Gallery: http://localhost:3003/book-review/doc/book/iterations/2026-10-25-leaning-together/index.html
''',encoding='utf-8')
editor_image='''<figure><img loading="lazy" src="leaning-editor.jpg" alt="Leaning Together selected in the saved live editor"><figcaption>One saved arrangement for desktop and VR. Select the whole work area or edit an individual member.</figcaption></figure>''' if (GALLERY/'leaning-editor.jpg').exists() else ''
html='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Leaning Together — hold, place, withdraw</title><style>
*{box-sizing:border-box}body{margin:0;background:#eee9df;color:#241f28;font:16px/1.55 system-ui,sans-serif}main{max-width:1320px;margin:auto;padding:40px 24px}h1{font-size:clamp(40px,7vw,86px);line-height:1;max-width:1000px}a{color:#7e2150;text-underline-offset:3px}p{max-width:850px}img{display:block;width:100%;height:auto}figure{margin:30px 0}figcaption{font-size:13px;margin-top:8px}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,450px),1fr));gap:24px}.note{border-left:4px solid #bd3a77;padding:14px 20px;background:#e8dce2}
</style><main><p>FLOOR 46 / SIX LOOSE PARTS / REAL CONTACT</p><h1>Leaning Together.<br>What holds what?</h1>
<p>Two planks, two wedges, a cube and a ball. Hold a part. Move a foot. Add a load. Withdraw your hand and see which posture can continue.</p>
<p><a href="/lab-editor?mode=void&floor=46">Open the saved work area in the live editor ↗</a> · <a href="/book-review/doc/book/iterations/2026-10-25-friction-studies/index.html">The neighbouring friction studies ↗</a></p>
<figure><img src="leaning-together.png" alt="Two loose timber planks leaning together between wooden chocks, with a white cube and ball on a supported board"><figcaption>The starting arrangement, after settling on the actual floor. Both wedges contact the plank feet; the planks contact each other.</figcaption></figure>
<p class="note">All six parts are live Jolt bodies from the start. No balancing joints, snapping or timed collapse. A held plank still contacts the other parts. The readout reports angles and time without hands, without grading the posture.</p>
<div class="grid"><figure><img src="leaning-withdrawn.png" alt="Changed plank posture after a foot wedge is withdrawn"><figcaption>Withdraw a foot chock: the arrangement changes through real contact physics.</figcaption></figure><figure><img src="leaning-load.png" alt="The native scene after an ivory cube is released above the planks"><figcaption>A cube released above the planks becomes a real load. These inspection interventions use a fixture hand; the desktop input view is below.</figcaption></figure></div>
<p>Desktop: <strong>right-click</strong> to hold/release, <strong>wheel</strong> for reach, <strong>Q/E</strong> to roll, <strong>Z/X</strong> to tilt, <strong>Shift+Q/E</strong> to yaw. VR: grip and turn your wrist. Reset releases held parts and restores your authored starting arrangement, with gravity immediately active.</p>
<figure><img loading="lazy" src="leaning-player.png" alt="Actual desktop player view of Leaning Together"><figcaption>The actual player approach. Walking all sides, pickup/movement/release of all six pieces, rotation and held reset were checked with desktop input and synthetic XR. Physical headset testing remains.</figcaption></figure>'''+editor_image+'''
<p>All ten members remain editable: six loose pieces, board, two supports and controls. Runtime hand arrangements are temporary; author reusable starting arrangements in the lab editor. Static editor previews show the authored start. A held body follows the native kinematic hand, without simulated muscle force or haptic feedback.</p></main></html>'''
(GALLERY/'index.html').write_text(html,encoding='utf-8');print(json.dumps(status))
